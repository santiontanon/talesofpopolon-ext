sin_table:
    dw 0, 6, 12, 18, 25, 31, 37, 43, 49, 56, 62, 68, 74, 80, 86, 92
    dw 97, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176
    dw 181, 185, 189, 193, 197, 201, 205, 209, 212, 216, 219, 222, 225, 228, 231, 234
    dw 236, 238, 241, 243, 244, 246, 248, 249, 251, 252, 253, 254, 254, 255, 255, 255
cos_table:
    dw 256, 255, 255, 255, 254, 254, 253, 252, 251, 249, 248, 246, 244, 243, 241, 238
    dw 236, 234, 231, 228, 225, 222, 219, 216, 212, 209, 205, 201, 197, 193, 189, 185
    dw 181, 176, 171, 167, 162, 157, 152, 147, 142, 136, 131, 126, 120, 115, 109, 103
    dw 97, 92, 86, 80, 74, 68, 62, 56, 49, 43, 37, 31, 25, 18, 12, 6
    dw 0, -6, -12, -18, -25, -31, -37, -43, -49, -56, -62, -68, -74, -80, -86, -92
    dw -97, -103, -109, -115, -120, -126, -131, -136, -142, -147, -152, -157, -162, -167, -171, -176
    dw -181, -185, -189, -193, -197, -201, -205, -209, -212, -216, -219, -222, -225, -228, -231, -234
    dw -236, -238, -241, -243, -244, -246, -248, -249, -251, -252, -253, -254, -254, -255, -255, -255
    dw -256, -255, -255, -255, -254, -254, -253, -252, -251, -249, -248, -246, -244, -243, -241, -238
    dw -236, -234, -231, -228, -225, -222, -219, -216, -212, -209, -205, -201, -197, -193, -189, -185
    dw -181, -176, -171, -167, -162, -157, -152, -147, -142, -136, -131, -126, -120, -115, -109, -103
    dw -97, -92, -86, -80, -74, -68, -62, -56, -49, -43, -37, -31, -25, -18, -12, -6
    dw 0, 6, 12, 18, 25, 31, 37, 43, 49, 56, 62, 68, 74, 80, 86, 92
    dw 97, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176
    dw 181, 185, 189, 193, 197, 201, 205, 209, 212, 216, 219, 222, 225, 228, 231, 234
    dw 236, 238, 241, 243, 244, 246, 248, 249, 251, 252, 253, 254, 254, 255, 255, 255

sin_table_x12:
    dw 0, 75, 150, 225, 301, 376, 450, 525, 599, 673, 746, 819, 891, 963, 1034, 1105
    dw 1175, 1244, 1313, 1381, 1448, 1514, 1579, 1643, 1706, 1768, 1829, 1889, 1948, 2006, 2063, 2118
    dw 2172, 2224, 2276, 2326, 2374, 2421, 2467, 2511, 2554, 2595, 2634, 2672, 2709, 2743, 2777, 2808
    dw 2838, 2866, 2892, 2916, 2939, 2960, 2979, 2997, 3012, 3026, 3038, 3048, 3057, 3063, 3068, 3071
cos_table_x12:
    dw 3072, 3071, 3068, 3063, 3057, 3048, 3038, 3026, 3012, 2997, 2979, 2960, 2939, 2916, 2892, 2866
    dw 2838, 2808, 2777, 2743, 2709, 2672, 2634, 2595, 2554, 2511, 2467, 2421, 2374, 2326, 2276, 2224
    dw 2172, 2118, 2063, 2006, 1948, 1889, 1829, 1768, 1706, 1643, 1579, 1514, 1448, 1381, 1313, 1244
    dw 1175, 1105, 1034, 963, 891, 819, 746, 673, 599, 525, 450, 376, 301, 225, 150, 75
    dw 0, -75, -150, -225, -301, -376, -450, -525, -599, -673, -746, -819, -891, -963, -1034, -1105
    dw -1175, -1244, -1313, -1381, -1448, -1514, -1579, -1643, -1706, -1768, -1829, -1889, -1948, -2006, -2063, -2118
    dw -2172, -2224, -2276, -2326, -2374, -2421, -2467, -2511, -2554, -2595, -2634, -2672, -2709, -2743, -2777, -2808
    dw -2838, -2866, -2892, -2916, -2939, -2960, -2979, -2997, -3012, -3026, -3038, -3048, -3057, -3063, -3068, -3071
    dw -3072, -3071, -3068, -3063, -3057, -3048, -3038, -3026, -3012, -2997, -2979, -2960, -2939, -2916, -2892, -2866
    dw -2838, -2808, -2777, -2743, -2709, -2672, -2634, -2595, -2554, -2511, -2467, -2421, -2374, -2326, -2276, -2224
    dw -2172, -2118, -2063, -2006, -1948, -1889, -1829, -1768, -1706, -1643, -1579, -1514, -1448, -1381, -1313, -1244
    dw -1175, -1105, -1034, -963, -891, -819, -746, -673, -599, -525, -450, -376, -301, -225, -150, -75
    dw 0, 75, 150, 225, 301, 376, 450, 525, 599, 673, 746, 819, 891, 963, 1034, 1105
    dw 1175, 1244, 1313, 1381, 1448, 1514, 1579, 1643, 1706, 1768, 1829, 1889, 1948, 2006, 2063, 2118
    dw 2172, 2224, 2276, 2326, 2374, 2421, 2467, 2511, 2554, 2595, 2634, 2672, 2709, 2743, 2777, 2808
    dw 2838, 2866, 2892, 2916, 2939, 2960, 2979, 2997, 3012, 3026, 3038, 3048, 3057, 3063, 3068, 3071
