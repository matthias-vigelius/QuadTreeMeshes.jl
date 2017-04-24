import graph;

size(20cm,20cm);
draw(scale(10)*unitsquare);
draw(shift(0.,0.)*scale(5)*unitsquare);
draw(shift(5.,0.)*scale(5)*unitsquare);
draw(shift(0.,5.)*scale(5)*unitsquare);
draw(shift(5.,5.)*scale(5)*unitsquare);


draw(shift(0.,0.)*scale(2.5)*unitsquare);
draw(shift(2.5,0.)*scale(2.5)*unitsquare);
draw(shift(0.,2.5)*scale(2.5)*unitsquare);
draw(shift(2.5,2.5)*scale(2.5)*unitsquare);

draw(shift(2.5, 2.5)*shift(0.,0.)*scale(1.25)*unitsquare, red);
draw(shift(2.5, 2.5)*shift(1.25,0.)*scale(1.25)*unitsquare, red);
draw(shift(2.5, 2.5)*shift(0.,1.25)*scale(1.25)*unitsquare, red);
draw(shift(2.5, 2.5)*shift(1.25,1.25)*scale(1.25)*unitsquare, red);
