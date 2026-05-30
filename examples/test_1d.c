/* test_1d.c -- write a 1D time-dependent SDF (for xvs).
   A standing-then-traveling sine wave, 21 points, 2 time levels.
   Build:  make        Run:  ./test_1d   ->  wave.sdf
   View :  xvs &  then  sdftoxvs wave.sdf                                   */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <bbhutil.h>

int main(void) {
    int    shape[1] = {21};
    double bbox[2]  = {0.0, 1.0};
    double data[21];
    int    i, k;

    for (k = 0; k < 2; k++) {
        double t = (double) k;
        for (i = 0; i < 21; i++) {
            double x = i / 20.0;
            data[i] = sin(6.2831853 * (x - 0.25 * t));
        }
        gft_out_bbox("wave", t, shape, 1, bbox, data);
    }
    printf("wrote wave.sdf (2 time levels, 21 pts)\n");
    return 0;
}
