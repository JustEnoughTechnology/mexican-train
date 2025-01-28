base = "C:\\development\\godot\\mexican-train\\common\\tiles"
p_dots = 3

for l in range (0,p_dots+1):
    for i in all_shapes():
        i.remove()
        for r in range(0,l+1):
            left = objects_from_svg_file(base+f"\\domino-{l}.svg",False)
            right = objects_from_svg_file(base+f"\\domino-{r}.svg",False)
            left = left[0]
            right = right[0]
            left.translate(-left.bounding_box().minimum)
            right.translate(-right.bounding_box().minimum )
            right.translate((42.0*px,0))
            save_file(base+f"\\domino-{l}-{r}.svg")
        
    
    

