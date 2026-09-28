#!/usr/bin/env python3
"""Generate AdShield-Rootless app/settings PNG assets using only Python stdlib."""
from pathlib import Path
import math, struct, zlib

ROOT = Path(__file__).resolve().parent.parent

def png_write(path, w, h, rgb):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
    raw = bytearray()
    stride = w * 3
    for y in range(h):
        raw.append(0)
        raw.extend(rgb[y*stride:(y+1)*stride])
    data = b'\x89PNG\r\n\x1a\n'
    data += chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    data += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
    data += chunk(b'IEND', b'')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)

def icon(size):
    S = max(2, 4 if size <= 120 else 2)
    w = h = size * S
    buf = bytearray(w*h*3)

    def put(x, y, c, a=1.0):
        if not (0 <= x < w and 0 <= y < h): return
        i = (y*w+x)*3
        for k in range(3):
            buf[i+k] = int(buf[i+k]*(1-a) + c[k]*a)

    cx, cy = w*0.5, h*0.48
    for y in range(h):
        for x in range(w):
            dx, dy = (x-cx)/w, (y-cy)/h
            r = min(1.0, math.sqrt(dx*dx+dy*dy)*1.8)
            top = max(0.0, 1.0-y/h)
            c = (int(2+5*top), int(9+22*(1-r)+12*top), int(18+46*(1-r)+45*top))
            i=(y*w+x)*3; buf[i:i+3]=bytes(c)

    def point_in_poly(px, py, poly):
        inside=False; j=len(poly)-1
        for i in range(len(poly)):
            xi,yi=poly[i]; xj,yj=poly[j]
            if ((yi>py)!=(yj>py)) and (px < (xj-xi)*(py-yi)/(yj-yi+1e-9)+xi): inside=not inside
            j=i
        return inside

    def fill_poly(poly, c, a=1.0):
        minx=max(0,int(min(x for x,_ in poly))); maxx=min(w-1,int(max(x for x,_ in poly)))
        miny=max(0,int(min(y for _,y in poly))); maxy=min(h-1,int(max(y for _,y in poly)))
        for yy in range(miny,maxy+1):
            for xx in range(minx,maxx+1):
                if point_in_poly(xx+.5,yy+.5,poly): put(xx,yy,c,a)

    def disc(x0,y0,r,c,a=1.0):
        r2=r*r
        for yy in range(max(0,int(y0-r)),min(h,int(y0+r)+1)):
            dy=yy-y0
            for xx in range(max(0,int(x0-r)),min(w,int(x0+r)+1)):
                dx=xx-x0
                if dx*dx+dy*dy<=r2: put(xx,yy,c,a)

    def line(x1,y1,x2,y2,width,c,a=1.0):
        dx=x2-x1; dy=y2-y1; n=max(1,int(math.hypot(dx,dy)))
        for t in range(n+1):
            q=t/n; disc(x1+dx*q,y1+dy*q,width/2,c,a)

    blue=(0,159,255); cyan=(0,221,255); steel=(195,213,230); dark=(5,17,31)

    for yy in (0.32,0.70):
        y=h*yy
        line(w*.05,y,w*.22,y,2*S,(0,92,190),.65)
        line(w*.78,y,w*.95,y,2*S,(0,92,190),.65)
        disc(w*.05,y,4*S,(0,154,255),.8); disc(w*.95,y,4*S,(0,154,255),.8)

    outer=[(w*.50,h*.11),(w*.82,h*.27),(w*.76,h*.69),(w*.50,h*.88),(w*.24,h*.69),(w*.18,h*.27)]
    inner=[(w*.50,h*.16),(w*.76,h*.30),(w*.70,h*.65),(w*.50,h*.81),(w*.30,h*.65),(w*.24,h*.30)]
    fill_poly(outer,blue,1); fill_poly(inner,dark,1)
    line(w*.50,h*.12,w*.81,h*.28,5*S,cyan,.8)
    line(w*.19,h*.28,w*.50,h*.12,5*S,cyan,.8)

    x1,y1,x2,y2=w*.34,h*.38,w*.66,h*.59
    for yy in range(int(y1),int(y2)):
        for xx in range(int(x1),int(x2)): put(xx,yy,(220,231,242),.93)
    for yy in range(int(y1+8*S),int(y2-8*S)):
        for xx in range(int(x1+8*S),int(x2-8*S)): put(xx,yy,(13,28,44),1)
    disc(x1+15*S,y1+13*S,3*S,steel,1); disc(x1+25*S,y1+13*S,3*S,steel,1)
    fill_poly([(x1+15*S,y2-18*S),(x1+35*S,y1+33*S),(x1+53*S,y2-18*S)],steel,.95)
    line(x1+58*S,y1+34*S,x2-14*S,y1+34*S,4*S,steel,.95)

    r0=w*.155
    for ang in range(0,360):
        a=math.radians(ang); x=cx+math.cos(a)*r0; y=cy+math.sin(a)*r0
        disc(x,y,5*S,cyan,.95)
    line(w*.39,h*.37,w*.65,h*.64,11*S,cyan,1)
    line(w*.395,h*.375,w*.645,h*.635,5*S,(120,235,255),.9)

    out=bytearray(size*size*3)
    area=S*S
    for oy in range(size):
        for ox in range(size):
            sums=[0,0,0]
            for sy in range(S):
                for sx in range(S):
                    i=((oy*S+sy)*w+(ox*S+sx))*3
                    sums[0]+=buf[i]; sums[1]+=buf[i+1]; sums[2]+=buf[i+2]
            j=(oy*size+ox)*3
            out[j:j+3]=bytes(v//area for v in sums)
    return out

def generate(path, size):
    png_write(path, size, size, icon(size))

assets = {
    ROOT/'app/Resources/Icon-60@2x.png':120,
    ROOT/'app/Resources/Icon-60@3x.png':180,
    ROOT/'app/Resources/Icon-76@2x.png':152,
    ROOT/'app/Resources/Icon-83.5@2x.png':167,
    ROOT/'preferences/Resources/AdShieldPrefs.png':58,
    ROOT/'layout/Library/PreferenceLoader/Preferences/AdShieldPrefs.png':58,
}
for p,s in assets.items(): generate(p,s)
print('Generated AdShield black/electric-blue shield assets')
