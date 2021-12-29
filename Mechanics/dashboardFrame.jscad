const jscad = require("@jscad/modeling");
const { roundedCuboid, cuboid, cylinder } = jscad.primitives;
const { subtract, union } = jscad.booleans;
const { translate, transform, rotateX } = jscad.transforms;
const { mat4 } = jscad.maths;


const gaugeWidth = 44.5;
const gaugeHeight = 44.5;
const gaugeRadius = 19.5;
const gaugeScrewRadius = 1.75;
const gaugeScrewOfsX = 5.5;
const gaugeScrewOfsY = 5;

const gaugeSpacing = 15;
const paddingVerticalTop = 5;
const paddingVerticalBottom = 15;
const paddingHorizontal = 15;
const boxWallThickness = 1.5;
const boxDepth = 35;

const skewAngle = -3.14*(15/180);
const numGauges = 2;


function hollowBox(width, height, depth, wall, skew) {
   return transform(mat4.fromValues(1, 0, 0, 0,
                                    0, 1, 0 ,0,
                                    0, Math.sin(skew), 1, 0,
                                    0, Math.sin(skew)*depth/2, 0, 1),    
    subtract(
     roundedCuboid({
        size: [width + 2*wall, height + 2*wall, depth],
         roundRadius: 2
             }),
     translate([0, 0, wall], 
                cuboid({size: [width, height, depth]})),
     translate([0, 0, (depth-3)/2], 
                  cuboid({size: [width + 2*wall, height + 2*wall, 3]}))
  
   ));
}

function gaugeDrill(depth) {
   return union(
             cylinder({height: depth*2, radius: gaugeRadius}),
             translate([gaugeWidth / 2 - gaugeScrewOfsX, gaugeHeight / 2 - gaugeScrewOfsY, 0], 
                        cylinder({height: depth, radius: gaugeScrewRadius})),
             translate([-gaugeWidth / 2 + gaugeScrewOfsX, gaugeHeight / 2 - gaugeScrewOfsY, 0], 
                        cylinder({height: depth, radius: gaugeScrewRadius}))
          );
}

function main() {
   const gaugeDrills = [];
   for(let gaugeIdx=0; gaugeIdx<numGauges; gaugeIdx++) {
      gaugeDrills.push(
         translate( [-(numGauges * gaugeWidth + (numGauges-1) * gaugeSpacing - gaugeWidth)/2 + gaugeIdx * (gaugeWidth+gaugeSpacing), 
                    (paddingVerticalTop-paddingVerticalBottom)/2, -boxDepth/2], 
                   gaugeDrill(2*boxWallThickness)));
   }

   return rotateX(0,
      subtract(
         hollowBox(
            numGauges * gaugeWidth + (numGauges-1) * gaugeSpacing + 2 * paddingHorizontal,
            gaugeHeight + paddingVerticalTop + paddingVerticalBottom,
            boxDepth,
            boxWallThickness, skewAngle
         ),
         gaugeDrills
         ));
}

module.exports = { main };

