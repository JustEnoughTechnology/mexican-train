
def mkdomino(l,r) :
    base = "C:\\development\\godot\\mexican-train-1\\common\\tiles"
    l1 = layer("L1")
    r1 = rect((0,0),(81*px,39*px),fill="black")
    r1.translate(-r1.bounding_box().minimum)
    l1.append(r1)
    left = objects_from_svg_file(base+f"\\domino-{l}.svg",False)
    right = objects_from_svg_file(base+f"\\domino-{r}.svg",False)
    left = left[0]
    right = right[0]
    l1.append(left)
    left.translate(-left.bounding_box().minimum)
    l1.append(right)
    right.translate(-right.bounding_box().minimum )
    right.translate((42.0*px,0))
    save_file(base+f"\\domino-{l}-{r}.svg")
    l1.remove()
    left.remove()
    right.remove()
    r1.remove()

p_dots = 12
for l in range (0,p_dots+1):
    for r in range(0,l+1):
        mkdomino(l,r)        
    

