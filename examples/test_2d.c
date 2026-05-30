/* test_2d.c -- write a 2D time-dependent SDF (for DV).
   An outgoing Gaussian-modulated ring, 41x41, 20 time levels -> animated
   surface in DV's local view.
   Build:  make        Run:  ./test_2d   ->  gauss2d.sdf
   View :  DV &   then  sdftodv gauss2d.sdf                                 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <bbhutil.h>

int main(void) {
    int    nx = 41, ny = 41, shape[2] = {nx, ny}, i, j, k;
    double bbox[4] = {-1.0, 1.0, -1.0, 1.0};
    double *d = (double *) malloc(nx * ny * sizeof(double));
    int    nt = 20;

    for (k = 0; k < nt; k++) {
        double t = k / (double)(nt - 1);
        for (j = 0; j < ny; j++)
            for (i = 0; i < nx; i++) {
                double x = -1.0 + 2.0 * i / (nx - 1);
                double y = -1.0 + 2.0 * j / (ny - 1);
                double r2 = x * x + y * y;
                d[i + nx * j] = exp(-8.0 * r2) * cos(6.2831853 * (sqrt(r2) - t));
            }
        gft_out_bbox("gauss2d", t, shape, 2, bbox, d);
    }
    printf("wrote gauss2d.sdf (%d levels, %dx%d)\n", nt, nx, ny);
    free(d);
    return 0;
}
