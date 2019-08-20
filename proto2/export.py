import bpy
import os
import sys
import traceback
import json
from mathutils import Vector
import numpy as np


TEST_SCENE_DIR = os.path.join(os.getcwd(), "assets/blender-2.80")
EXPORTED_DIR = os.path.join(os.getcwd(), ".")

def export_escn(out_file, config):
    """Fake the export operator call"""
    import io_scene_godot
    io_scene_godot.export(out_file, config)

def split_export(out_dir, config):
    SOURCE_SCENE = os.path.join(os.getcwd(), "assets", "blender-2.80", "common-all.blend")
    EXPORT_DIR = os.path.join(os.getcwd(), "assets", "blender-2.80", "exports")
    SCENE_DIR = os.path.join(os.getcwd(), "assets", "blender-2.80")
    CHARACTER_DIR = out_dir
    SHAPES_PER_PART = 12
    def make_part_list(shapes):
        part_no = 0
        ret = {}
        part_shapes = []
        for k in shapes:
            if len(part_shapes) < SHAPES_PER_PART:
                part_shapes.append(k)
            else:
                fn = "common_part%d.blend" % (part_no)
                ret[fn] = part_shapes
                part_shapes = [k]
                part_no += 1
        ret["common_part%d.blend" % (part_no)] = part_shapes
        return ret

    base_config = config
    shape_list = []
    result_data = {}
    if os.path.exists(os.path.join(CHARACTER_DIR, "data.json")):
        result_data = json.load(open(os.path.join(CHARACTER_DIR, "data.json")))
    result_data["files"] = []
#        bpy.ops.wm.open_mainfile(filepath=config["source"])
    if not os.path.exists(EXPORT_DIR):
        os.makedirs(EXPORT_DIR)

    for shape_key_iter in bpy.data.objects["base"].data.shape_keys.key_blocks:
        if shape_key_iter.name != "Basis":
            shape_list.append(shape_key_iter.name)
    split_list = make_part_list(shape_list)
    for fn in split_list.keys():
        bpy.ops.wm.save_mainfile(filepath=os.path.join(EXPORT_DIR, fn), check_existing=False)
    for fn in split_list.keys():
        bpy.ops.wm.open_mainfile(filepath=os.path.join(EXPORT_DIR, fn))
        for ob in bpy.data.objects:
            if ob.name == "base" or ob.name.endswith("_helper"):
                for shape_key_iter in ob.data.shape_keys.key_blocks:
                    if not shape_key_iter.name in split_list[fn] + ["Basis"]:
                        ob.shape_key_remove(shape_key_iter)
        bpy.ops.wm.save_mainfile(filepath=os.path.join(EXPORT_DIR, fn), check_existing=False)
        out_path = os.path.join(
            CHARACTER_DIR,
            fn.replace('.blend', '.escn')
            )
        export_escn(out_path, base_config)
        result_data["files"].append(os.path.join("characters", "common", fn.replace('.blend', '.escn')))
    print("Exported to {}".format(os.path.abspath(out_path)))
    fd = open(os.path.join(CHARACTER_DIR, "data.json"), "w")
    fd.write(json.dumps(result_data, indent=4, sort_keys=True))
    fd.close()
    print("Exported to {}".format(os.path.abspath(out_path)))

def main():
    dir_queue = list()
    dir_queue.append('.')
    while dir_queue:
        dir_relpath = dir_queue.pop(0)

        # read config file if present, otherwise use default
        src_dir_path = os.path.join(TEST_SCENE_DIR, dir_relpath)
        if os.path.exists(os.path.join(src_dir_path, "config.json")):
            with open(os.path.join(src_dir_path, "config.json")) as config_file:
                base_config = json.load(config_file)
        else:
            base_config = {
                        "outpath": "exports",
                        "collections": [],
                        "split": False,
                        "use_visible_objects": True,
                        "use_export_selected": False,
                        "use_mesh_modifiers": True,
                        "use_exclude_ctrl_bone": False,
                        "use_export_animation": True,
                        "use_export_material": True,
                        "use_export_shape_key": True,
                        "use_stashed_action": True,
                        "use_beta_features": True,
                        "generate_external_material": False,
                        "animation_modes": "ACTIONS",
                        "object_types": ["EMPTY", "LIGHT", "ARMATURE", "GEOMETRY"]
                     }

        # create exported to directory
        exported_dir_path = os.path.join(EXPORTED_DIR, dir_relpath)
        if not os.path.exists(exported_dir_path):
            os.makedirs(exported_dir_path)

        for item in os.listdir(os.path.join(TEST_SCENE_DIR, dir_relpath)):
            item_abspath = os.path.join(TEST_SCENE_DIR, dir_relpath, item)
            if os.path.isdir(item_abspath):
                # push dir into queue for later traversal
                dir_queue.append(os.path.join(dir_relpath, item))
            elif item_abspath.endswith('blend'):
                config = {}
                for k, v in base_config.items():
                    if k == "object_types":
                        config[k] = set(v)
                    else:
                        config[k] = v
                cpath = item_abspath.replace('.blend', '.json')
                if os.path.exists(cpath):
                    _config = json.load(open(cpath))
                    for k, v in _config.items():
                        if k == "object_types":
                            config[k] = set(v)
                        else:
                            config[k] = v
                # export blend file
                print("---------")
                print("Exporting {}".format(os.path.abspath(item_abspath)))
                bpy.ops.wm.open_mainfile(filepath=item_abspath)
                dirpath = os.path.join(EXPORTED_DIR,
                    dir_relpath,
                    config["outpath"]
                    )
                if not os.path.exists(dirpath):
                    os.makedirs(dirpath, 0o755, True)

                out_path = os.path.join(
                    EXPORTED_DIR,
                    dir_relpath,
                    config["outpath"],
                    item.replace('.blend', '.escn')
                    )
                if config["split"]:
                    config["source"] = item_abspath
                    out_path = os.path.join(
                        EXPORTED_DIR,
                        dir_relpath,
                        config["outpath"]
                    )
                    split_export(out_path, config)
                elif len(config["collections"]) > 0:
                    for cur_col in config["collections"]:
                        col_keep = {}
                        for c in bpy.data.collections:
                            col_keep[c.name] = c.hide_viewport
                            if c.name == cur_col:
                                c.hide_viewport = False
                            elif c.name in config["collections"]:
                                c.hide_viewport = True
                        out_path = os.path.join(
                            EXPORTED_DIR,
                            dir_relpath,
                            config["outpath"],
                            item.replace('.blend', '') + "_" + cur_col + ".escn"
                            )
                        export_escn(out_path, config)
                        for c in bpy.data.collections:
                            c.hide_viewport=col_keep[c.name]
                        print("Exported to {}".format(os.path.abspath(out_path)))
                else:
                    out_path = os.path.join(
                        EXPORTED_DIR,
                        dir_relpath,
                        config["outpath"],
                        item.replace('.blend', '.escn')
                        )
                    export_escn(out_path, config)
                    print("Exported to {}".format(os.path.abspath(out_path)))


def run_with_abort(function):
    """Runs a function such that an abort causes blender to quit with an error
    code. Otherwise, even a failed script will allow the Makefile to continue
    running"""
    try:
        function()
    except:
        traceback.print_exc()
        exit(1)


if __name__ == "__main__":
    run_with_abort(main)
