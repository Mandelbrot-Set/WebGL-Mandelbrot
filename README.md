# 优化选项

- 渲染器文件改成glsl格式文件，便于阅读和修改
- 改用async异步加载glsl文件
- 怎么运行? for Mac, `python -m SimpleHTTPServer`, then, access `http://localhost:8000`

# 算法解析
    1、对位置pos考虑宽高比、旋转、缩放、平移因素，再进行计算
    2、根据对pos的进一步预处理方法，分成九种模式：
       1) 保持
       2) 取crecpcl, 先计算出pos实部、虚部的平方和，如果为0，pos取原点值，否则pos实部、虚部分别除以平方和。
       3) ccos操作：实部变为：cos(a.re) * cosh(a.im)，虚部变为：-sinh(a.im) * sin(a.re)
       4) ctan操作：
          CNum ctan(CNum a) {
            float den = cos(2.0 * a.re) + cosh(2.0 * a.im);
            return CNum(sin(2.0 * a.re) / den, sinh(2.0 * a.im) / den);
          }
       5) cpow操作：c = cpow(c, CNum(var1, 0.0));
           CNum cpow(CNum a, CNum b) {
            if (b.re == 0.0 && b.im == 0.0) return CNum(1.0, 0.0);
            if (b.im == 0.0) return cpow(a, b.re);
            float r = cmod(a);
            float p = carg(a);
            float c = b.im * log(r) + b.re * p;
            float d = pow(r, b.re) * exp(-b.im * p);
            return CNum(d * cos(c), d * sin(c));
           }
       6) csin操作：CNum csin(CNum a) { return CNum(sin(a.re) * cosh(a.im), cos(a.re) * sinh(a.im));}
       7) clog操作：c = clog(c, CNum(var1, 0.0));
       
           CNum clog(CNum a, CNum b) {
            return cdiv(cln(a), cln(b));
           }
           CNum cdiv(CNum a, CNum b) {
           	float den = b.re * b.re + b.im * b.im;
           	return CNum((a.re * b.re + a.im * b.im) / den, (a.im * b.re + a.re * b.im) / den);
           }
           
       8) 和4一样
       9) cmul操作： c = cmul(crecpcl(c), clog(c, CNum(var1, 0.0)));
           CNum cmul(CNum a, CNum b) {
            return CNum(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re);
           }
           
    3、曼德波集合计算，根据innerMode，可有三种不同计算方式，每种计算结果展示的内容不同。
        float calcIter1(CNum c) {
            CNum z = CNum(0.0, 0.0);
            for (int i = 0; i < ITER_UPPER_BOUND; i++) {
                if (i >= maxIter) break;
                z = csquare(z);
                z = cadd(z, c);
                if (cmodsq(z) > 4.0) {
                    z = csquare(z);
                    z = cadd(z, c);
                    z = csquare(z);
                    z = cadd(z, c);
                    float mod = cmod(z);
                    if (mod <= 1.0) return float(i);
                    float mu = float(i) - log(log(mod)) / ln2;
                    if (mu < 0.0) return 0.0;
                    return mu;
                }
            }
            return float(maxIter);
        }
        float calcIter2(CNum c) {
            CNum z = CNum(0.0, 0.0);
            for (int i = 0; i < ITER_UPPER_BOUND; i++) {
                if (i >= maxIter) break;
                z = csquare(z);
                z = cadd(z, c);
                z = crecpcl(z);
                if (cmodsq(z) > 4.0) {
                    z = csquare(z);
                    z = cadd(z, c);
                    z = csquare(z);
                    z = cadd(z, c);
                    float mod = cmod(z);
                    if (mod <= 1.0) return float(i);
                    float mu = float(i) - log(log(mod)) / ln2;
                    if (mu < 0.0) return 0.0;
                    return mu;
                }
            }
            return float(maxIter);
        }
        float calcIter3(CNum c) {
            CNum z = CNum(0.0, 0.0);
        
            for (int i = 0; i < ITER_UPPER_BOUND; i++) {
                if (i >= maxIter) break;
                z = csquare(z);
                z = cadd(z, c);
                z = ccos(z);
                if (cmodsq(z) > 4.0) {
                    z = csquare(z);
                    z = cadd(z, c);
                    z = csquare(z);
                    z = cadd(z, c);
                    float mod = cmod(z);
                    if (mod <= 1.0) return float(i);
                    float mu = float(i) - log(log(mod)) / ln2;
                    if (mu < 0.0) return 0.0;
                    return mu;
                }
            }
            return float(maxIter);
        }
    
# WebGL-Mandelbrot

WebGL-Mandelbrot is an interactive browser-based Mandelbrot & Julia Set renderer

Features:
- realtime rendering and updating of the Mandelbrot Set and its corresponding Julia Set
- selection of nine different "custom Mandelbrot/Julia sets" that use different iterative algorithms

- customizable position and zoom
- customizable detail level
- customizable colour
- customizable rotation

Screenshot:
![alt](https://github.com/Pilex1/WebGL-Mandelbrot/blob/master/Sample.png)
Copyright Alex Tan 2017
