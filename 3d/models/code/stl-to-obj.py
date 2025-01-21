import bpy
import os

def convert_stl_to_obj(source_dir, target_dir):
    """
    Convert all STL files in the source directory to OBJ files in the target directory.

    :param source_dir: Path to the directory containing STL files.
    :param target_dir: Path to the directory to save OBJ files.
    """
    if not os.path.exists(source_dir):
        print(f"Source directory {source_dir} does not exist.")
        return
    print (source_dir)
    print(target_dir)
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)

    for filename in os.listdir(source_dir):
        if filename.endswith(".stl"):
            print (filename)
            stl_path = os.path.join(source_dir, filename)

            # Load STL file
            bpy.ops.import_mesh.stl(filepath=stl_path)
            bpy.ops.models. 
            # Get the imported object (assumes the last object is the imported one)
            obj = bpy.context.selected_objects[0]

            # Create the target file path
            obj_filename = os.path.splitext(filename)[0] + ".obj"
            obj_path = os.path.join(target_dir, obj_filename)

            # Export as OBJ
            
            bpy.ops.export_scene.obj(filepath=obj_path, use_selection=True)

            # Delete the imported object to keep the scene clean
            bpy.data.objects.remove(obj, do_unlink=True)

            print(f"Converted {filename} to {obj_filename}")

    print("Conversion completed.")

# Update these paths as needed
source_directory = "C:\\development\\godot\\mexican-train\\models\\stl"
target_directory = "C:\\development\\godot\\mexican-train\\models\\obj"

convert_stl_to_obj(source_directory, target_directory)