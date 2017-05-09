import graph;
import geometry;

size(20cm,20cm);

real mscale = 5.;
real bdy = 1.;
pair n = (0.5, 1.);
pair nne = (0.75, 1.);
pair ne = (1., 1.);
pair nee = (1., 0.75);
pair e = (1., 0.5);
pair see = (1., 0.25);
pair se = (1., 0.);
pair sse = (0.75, 0.);
pair s = (0.5, 0.);
pair ssw = (0.25, 0.);
pair sw = (0., 0.);
pair sww = (0., 0.25);
pair w = (0., 0.5);
pair nww = (0., 0.75);
pair nw = (0., 1.);
pair nnw = (0.25, 1.);
pair c = (0.5, 0.5);

pair myshift(int i, int j)
{
  return (i * (mscale + bdy), j *  (mscale + bdy));
}

path mySquare(int i, int j)
{
  return shift(myshift(i,j)) * scale(mscale) * unitsquare;
}

void drawSquareLabels(int i, int j)
{
  dot(Label("1"), shift(myshift(i, j)) * scale(mscale)*sw, red);
  dot(Label("3"), shift(myshift(i, j)) * scale(mscale)*s, red);
  dot(Label("5"), shift(myshift(i, j)) * scale(mscale)*se, red);
  dot(Label("7"), shift(myshift(i, j)) * scale(mscale)*e, red);
  dot(Label("9"), shift(myshift(i, j)) * scale(mscale)*ne, red);
  dot(Label("11"), shift(myshift(i, j)) * scale(mscale)*n, red);
  dot(Label("13"), shift(myshift(i, j)) * scale(mscale)*nw, red);
  dot(Label("15"), shift(myshift(i, j)) * scale(mscale)*w, red);
}

// if the boundary is aligned with a cell edge, we just add a vertex
// in the center and connect to all occupied points

draw(mySquare(2,2));
dot(Label("N"), shift(myshift(2,2)) * scale(mscale)*n, red);
dot(Label("NEE"), shift(myshift(2,2)) * scale(mscale)*nee, red);
draw((shift(myshift(2,2)) * scale(mscale)*n
      -- shift(myshift(2,2)) * scale(mscale)*nee
      ), red);
draw((shift(myshift(2,2)) * scale(mscale)*n
      -- shift(myshift(2,2)) * scale(mscale)*c));
draw((shift(myshift(2,2)) * scale(mscale)*nee
      -- shift(myshift(2,2)) * scale(mscale)*c));
draw((shift(myshift(2,2)) * scale(mscale)*e
      -- shift(myshift(2,2)) * scale(mscale)*c), dashed);
draw((shift(myshift(2,2)) * scale(mscale)*se
      -- shift(myshift(2,2)) * scale(mscale)*c));
draw((shift(myshift(2,2)) * scale(mscale)*s
      -- shift(myshift(2,2)) * scale(mscale)*c), dashed);
draw((shift(myshift(2,2)) * scale(mscale)*sw
      -- shift(myshift(2,2)) * scale(mscale)*c));
draw((shift(myshift(2,2)) * scale(mscale)*w
      -- shift(myshift(2,2)) * scale(mscale)*c), dashed);
draw((shift(myshift(2,2)) * scale(mscale)*nw
      -- shift(myshift(2,2)) * scale(mscale)*c));

int sx = 1;
int sy = 1;
draw(mySquare(sx, sy));
dot(Label("N"), shift(myshift(sx, sy)) * scale(mscale)*n, red);
dot(Label("E"), shift(myshift(sx, sy)) * scale(mscale)*e, red);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*e
      ), red);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*e
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*se
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*s
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*sw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*w
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*nw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));

sx = 2;
sy = 1;
draw(mySquare(sx, sy));
dot(Label("N"), shift(myshift(sx, sy)) * scale(mscale)*n, red);
dot(Label("SEE"), shift(myshift(sx, sy)) * scale(mscale)*see, red);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*see
      ), red);
draw((shift(myshift(sx, sy)) * scale(mscale)*see
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*e), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*see
      -- shift(myshift(sx, sy)) * scale(mscale)*s));
draw((shift(myshift(sx, sy)) * scale(mscale)*s
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*sw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*w
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*nw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));

sx = 1;
sy = 2;
draw(mySquare(sx, sy));
dot(Label("N"), shift(myshift(sx, sy)) * scale(mscale)*n, red);
dot(Label("SEE"), shift(myshift(sx, sy)) * scale(mscale)*see, red);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*se
      ), red);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*e), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*se
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*s
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*sw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*w
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*nw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));

sx = 1;
sy = 3;
draw(mySquare(sx, sy));
dot(Label("N"), shift(myshift(sx, sy)) * scale(mscale)*n, red);
dot(Label("SSE"), shift(myshift(sx, sy)) * scale(mscale)*sse, red);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*sse
      ), red);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*e), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*sse
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*s
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*sw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*w
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*nw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*sse
      -- shift(myshift(sx, sy)) * scale(mscale)*e), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*sse
      -- shift(myshift(sx, sy)) * scale(mscale)*ne), dotted);

sx = 2;
sy = 3;
draw(mySquare(sx, sy));
dot(Label("N"), shift(myshift(sx, sy)) * scale(mscale)*n, red);
dot(Label("S"), shift(myshift(sx, sy)) * scale(mscale)*s, red);
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*s
      ), red);
draw((shift(myshift(sx, sy)) * scale(mscale)*c
      -- shift(myshift(sx, sy)) * scale(mscale)*e), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*sw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*ne
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*se
      -- shift(myshift(sx, sy)) * scale(mscale)*c));
draw((shift(myshift(sx, sy)) * scale(mscale)*w
      -- shift(myshift(sx, sy)) * scale(mscale)*c), dashed);
draw((shift(myshift(sx, sy)) * scale(mscale)*nw
      -- shift(myshift(sx, sy)) * scale(mscale)*c));

// no segment
// bits correspond to SWNE

// 0000
sx = 4;
sy = 1;
draw(mySquare(sx, sy));
drawSquareLabels(sx, sy);
draw((shift(myshift(sx, sy)) * scale(mscale)*nw
      -- shift(myshift(sx, sy)) * scale(mscale)*se));

// 1000 = 0100 = 0010 = 0001
sx = 5;
sy = 1;
draw(mySquare(sx, sy));
draw((shift(myshift(sx, sy)) * scale(mscale)*nw
      -- shift(myshift(sx, sy)) * scale(mscale)*s));
draw((shift(myshift(sx, sy)) * scale(mscale)*ne
      -- shift(myshift(sx, sy)) * scale(mscale)*s));

// 1100 = 0110 = 0011 = 1001
sx = 4;
sy = 2;
draw(mySquare(sx, sy));
draw((shift(myshift(sx, sy)) * scale(mscale)*w
      -- shift(myshift(sx, sy)) * scale(mscale)*s));
draw((shift(myshift(sx, sy)) * scale(mscale)*w
      -- shift(myshift(sx, sy)) * scale(mscale)*ne));
draw((shift(myshift(sx, sy)) * scale(mscale)*s
      -- shift(myshift(sx, sy)) * scale(mscale)*ne));

// 1010 = 0101
sx = 5;
sy = 2;
draw(mySquare(sx, sy));
draw((shift(myshift(sx, sy)) * scale(mscale)*w
      -- shift(myshift(sx, sy)) * scale(mscale)*e));
draw((shift(myshift(sx, sy)) * scale(mscale)*nw
      -- shift(myshift(sx, sy)) * scale(mscale)*e));
draw((shift(myshift(sx, sy)) * scale(mscale)*sw
      -- shift(myshift(sx, sy)) * scale(mscale)*e));


// 1101 = 1011 = 0111 = 1110
sx = 4;
sy = 3;
draw(mySquare(sx, sy));
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*s));
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*w));
draw((shift(myshift(sx, sy)) * scale(mscale)*s
      -- shift(myshift(sx, sy)) * scale(mscale)*w));
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*se));

// 1111
sx = 5;
sy = 3;
draw(mySquare(sx, sy));
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*s));
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*w));
draw((shift(myshift(sx, sy)) * scale(mscale)*s
      -- shift(myshift(sx, sy)) * scale(mscale)*w));
draw((shift(myshift(sx, sy)) * scale(mscale)*n
      -- shift(myshift(sx, sy)) * scale(mscale)*e));
draw((shift(myshift(sx, sy)) * scale(mscale)*s
      -- shift(myshift(sx, sy)) * scale(mscale)*e));
