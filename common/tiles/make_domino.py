def mkdomino(l_parm,r_parm) :
    print(f"Making domino {l_parm}-{r_parm}")
    base = "C:\\development\\godot\\mexican-train\\common\\tiles"
    l1 = layer("L1")
    r1 = rect((0,0),(81*px,39*px),fill="black")
    r1.translate(-r1.bounding_box().minimum)
    l1.append(r1)
    left = objects_from_svg_file(base+f"\\domino-{l_parm}.svg",False)
    right = objects_from_svg_file(base+f"\\domino-{r_parm}.svg",False)
    left = left[0]
    right = right[0]
    l1.append(left)
    left.translate(-left.bounding_box().minimum)
    l1.append(right)
    right.translate(-right.bounding_box().minimum )
    right.translate((42.0*px,0))
    save_file(base+f"\\domino-{l_parm}-{r_parm}.svg")
    print (f"Removing domino {l_parm}-{r_parm}")
    print(f"{l1}")
    l1.remove()
    #print(f"{left}")
    #left.remove()
    #print(f"{right}")
    #right.remove()
    #print(f"{r1}")
    #r1.remove()
p_dots = 18
for ll in range (0,p_dots+1):
    for rr in range(0,ll+1):
        mkdomino(ll,rr)  