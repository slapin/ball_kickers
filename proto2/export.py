import bpy
import os
import sys
import traceback
import json

TEST_SCENE_DIR = os.path.join(os.getcwd(), "assets/blender-2.80")
EXPORTED_DIR = os.path.join(os.getcwd(), ".")

def export_escn(out_file, config):
    """Fake the export operator call"""
    import io_scene_godot
    io_scene_godot.export(out_file, config)

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
                if len(config["collections"]) > 0:
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
