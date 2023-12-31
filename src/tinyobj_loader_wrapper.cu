/*
 * Copyright (c) 2021-2022, NVIDIA CORPORATION.  All rights reserved.
 *
 * NVIDIA CORPORATION and its licensors retain all intellectual property
 * and proprietary rights in and to this software, related documentation
 * and any modifications thereto.  Any use, reproduction, disclosure or
 * distribution of this software and related documentation without an express
 * license agreement from NVIDIA CORPORATION is strictly prohibited.
 */

/** @file   tinyobj_loader_wrapper.cpp
 *  @author Thomas Müller, NVIDIA
 *  @brief  Wrapper around the tinyobj_loader library, providing a simple
 *          interface to load OBJ-based meshes.
 */

#include <neural-graphics-primitives/common_host.h>
#include <neural-graphics-primitives/tinyobj_loader_wrapper.h>

#include <fmt/core.h>

#define TINYOBJLOADER_IMPLEMENTATION
#include <tinyobjloader/tiny_obj_loader.h>

#include <vector>

namespace ngp {

std::vector<vec3> load_obj(const fs::path& path) {
	tinyobj::attrib_t attrib;
	std::vector<tinyobj::shape_t> shapes;
	std::vector<tinyobj::material_t> materials;

	std::string warn;
	std::string err;

	std::ifstream f{native_string(path), std::ios::in | std::ios::binary};
	bool ret = tinyobj::LoadObj(&attrib, &shapes, &materials, &warn, &err, &f);

	if (!warn.empty()) {
		tlog::warning() << warn << " while loading '" << path.str() << "'";
	}

	if (!err.empty()) {
		throw std::runtime_error{fmt::format("Error loading '{}': {}", path.str(), err)};
	}

	std::vector<vec3> result;

	tlog::success() << "Loaded mesh \"" << path.str() << "\" file with " << shapes.size() << " shapes.";

	// Loop over shapes
	for (size_t s = 0; s < shapes.size(); s++) {
		// Loop over faces
		size_t index_offset = 0;
		for (size_t f = 0; f < shapes[s].mesh.num_face_vertices.size(); f++) {
			size_t fv = size_t(shapes[s].mesh.num_face_vertices[f]);

			if (shapes[s].mesh.num_face_vertices[f] != 3) {
				tlog::warning() << "Non-triangle face found in " << path.str();
				index_offset += fv;
				continue;
			}

			// Loop over vertices in the face.
			for (size_t v = 0; v < 3; v++) {
				tinyobj::index_t idx = shapes[s].mesh.indices[index_offset + v];

				const tinyobj::real_t vx = attrib.vertices[3*idx.vertex_index+0];
				const tinyobj::real_t vy = attrib.vertices[3*idx.vertex_index+1];
				const tinyobj::real_t vz = attrib.vertices[3*idx.vertex_index+2];

				result.emplace_back(vx, vy, vz);
			}

			index_offset += fv;
		}
	}

	return result;
}

}
