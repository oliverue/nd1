////////////////////////////////////////////////////////////////////////////
//
//                       Copyright (c) 2007-2009
//                       Future Team Aps 
//                       Denmark
//
//                       All Rights Reserved
//
//   This source file is subject to the terms and conditions of the
//   Future Team Software License Agreement which restricts the manner
//   in which it may be used.
//   Mail: hve@hvks.com
//
/////////////////////////////////////////////////////////////////////////////
//
// Module name     :    integrationbase.js
// Module ID Nbr   :   
// Description     :   Javascript integration base class
// --------------------------------------------------------------------------
// Change Record   :   
//
// Version  Author/Date     Description of changes
// -------  --------------- ----------------------
//  01.01   HVE/2007-Apr-16 Initial release
//  02.03   HVE/2007-May-19 Added Gauss-Legendre and Gauss-Chebyshev
//  02.04   HVE/2007-May-25 Added Gauss-Hermit
//  02.05   HVE/2007-Jun-13 Corrected a bug in calculation of q
//  02.06   HE/Nov-15-2009  Added Double Exponetial integration method
// End of Change Record
//
/////////////////////////////////////////////////////////////////////////////

// New Integration Object
// Class Constructor. 
function Integration(eq)
    {
    this.eq=eq;
    try{this.func=new Function("x","with(Math) return "+eq);}
    catch(e){ alert(e+" equation="+eq); return;}    
    this.cnt=0;         // Statistics
    this.i=new Array;   // Iterations
    this.q=new Array; // Convergence power  
    this.intgmethod=""; //if(this.i[this.i.length-2]-this.i[this.i.length-3]==0) this.q[this.q.length]=1 else
    this.convergence=new Function("","with(Math) {if(this.i.length>2){var x=this.i[this.i.length-1]-this.i[this.i.length-2]; var y=this.i[this.i.length-2]-this.i[this.i.length-3];if(x==0) this.q[this.q.length]=0; else this.q[this.q.length]=abs((LOG2E*log(abs(x/y)))).toFixed(2);}}");
    }
    
// Class Prototypes
Integration.prototype.toString=function() {return this.eq;}
Integration.prototype.valueof=function() { return this.func; }
Integration.prototype.value=function(x) //Evaluate f(x). 
    {var f;
    try{f=eval(this.func(Number(x)));}
    catch(e){alert(e);return Number.NaN;}
    this.cnt++; return Number(f);
    }
Integration.prototype.iteration=function(s) {this.i[this.i.length]=s; this.convergence();}  
Integration.prototype.reset=function() {this.i.length=0; this.q.length=0; this.cnt=0;}
Integration.prototype.method=function(m) {if(arguments.length==0) return this.intgmethod; else this.intgmethod=m;}


// Integration Midtpoint
Integration.prototype.midtpoint=function(a,b)
    {
    function Midtpoint(o,a,b,n) {var h=(b-a)/n; var s=0;for(var j=1;j<=n;j++){s+=o.value(Number(a)+h/2*(2*j-1));}s*=h;return s;}

    var s, s0, dx0, dx, i, eps;
    if(a==b)return 0;   if(arguments.length==3) return Midtpoint(this,a,b,arguments[2]);
    eps=Math.pow(2,-54); this.reset(); this.method("Midtpoint"); // Fixed n 
    for(i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=32768;dx0=dx,s0=s,i*=2)
        {
        s=Midtpoint(this,a,b,i);
        dx=Math.abs(s-s0); this.iteration(s); if(dx==0) break;
        if(this.i.length>2){if(dx<eps*(i+1)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);              
    return s;
    }
// Integration Trapez
Integration.prototype.trapez=function(a,b)
    {
    function Trapez(o,a,b,n)
        {var h=(b-a)/n; 
        if(arguments.length==5)//Previous sum from the 2n intervals. Avoid half the function evalaution
            {var s=arguments[4]/(2*h); for(var j=1;j<n;j+=2){s+=o.value(Number(a)+j*h);}}
        else
            {var s=0.5*(o.value(a)+o.value(b)); for(var j=1;j<n;j++){s+=o.value(Number(a)+j*h);}}
        s*=h;   return s;
        }

    var s, s0, dx0, dx, i, eps;
    if(a==b)return 0;   if(arguments.length==3) return Trapez(this,a,b,arguments[2]); 
    eps=Math.pow(2,-54); this.reset();  this.method("Trapez"); // Fixed n 
    for(i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=32768;dx0=dx,s0=s,i*=2)
        {if(i==1) s=Trapez(this,a,b,i); else s=Trapez(this,a,b,i,s);
        dx=Math.abs(s-s0);  this.iteration(s);  if(dx==0) break; 
        if(this.i.length>2){if(dx<eps*(i+1)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);      
    return s;
    }
// Integration Simpson
Integration.prototype.simpson=function(a,b)
    {
    function Simpson(o,a,b,n)
        {var h=(b-a)/(2*n); var s=o.value(a)+o.value(b); var s1=0, s2=0;
        for(var j=1;j<=n;j++){var x=Number(a)+2*j*h; s1+=o.value(x-h);  if(j<n) s2+=o.value(x);}
        s+=4*s1+2*s2;s*=h/3;    return s;
        }

    var s, s0, dx0, dx, eps;
    if(a==b)return 0;
    if(arguments.length==3) return Simpson(this,a,b,arguments[2]);
    eps=Math.pow(2,-54); this.reset();  this.method("Simpson"); // Fixed n
    for(var i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=32768;dx0=dx,s0=s,i*=2)
        {
        s=Simpson(this,a,b,i);
        dx=Math.abs(s-s0); this.iteration(s); if(dx==0) break; 
        if(this.i.length>2){if(dx<eps*(2*i+5)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);      
    return s;
    }
// Integration Romberg
Integration.prototype.romberg=function(a,b)
    {
    var s, s0, dx0, dx, max_r, tr=true, T=new Array, eps;
    if(a==b)return 0;   if(arguments.length==3) max_r=arguments[2]; else max_r=15; 
    eps=Math.pow(2,-54); this.reset();  this.method("Romberg"); // Fixed max r
    for(var r=0,i=1,s0=0,dx0=Number.POSITIVE_INFINITY;r<=max_r;dx0=dx,s0=s,r++,i*=2)
        {
        T[r]=new Array;
        T[r][0]=tr?this.trapez(a,b,i):this.midtpoint(a,b,i); if(tr&&isFinite(T[r][0])==false) {tr=false; T[r][0]=this.midtpoint(a,b,i);}
        if(r>0) for(var j=1,pp=4;j<=r;j++,pp*=4){T[r][j]=T[r][j-1]+(T[r][j-1]-T[r-1][j-1])/(pp-1);}
        s=T[r][r]; this.iteration(s);   dx=Math.abs(s-s0); if(dx==0) break; 
        if(r>=2){if(dx<eps*(i+1+r*5)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);  delete T;   
    return s;
    }
// Integration Fox-Romberg
Integration.prototype.foxromberg=function(a,b)
    {
    var s, s0, dx0, dx, max_r,tr=true, q=0, T=new Array, eps;
    if(a==b)return 0;   if(arguments.length==3) max_r=arguments[2]; else max_r=15; 
    eps=Math.pow(2,-54); this.reset();  this.method("Romberg"); // Fixed max r
    // Make a pre trial run with regular Romberg to determine convergence power q
    for(var r=0,i=1,s0=0,dx0=Number.POSITIVE_INFINITY;r<=max_r;dx0=dx,s0=s,r++,i*=2)
        {
        T[r]=new Array;
        T[r][0]=tr?this.trapez(a,b,i):this.midtpoint(a,b,i); if(tr&&isFinite(T[r][0])==false) {tr=false; T[r][0]=this.midtpoint(a,b,i);}
        if(r>0) for(var j=1,pp=4;j<=r;j++,pp*=4){T[r][j]=T[r][j-1]+(T[r][j-1]-T[r-1][j-1])/(pp-1);}
        s=T[r][r]; this.iteration(s);   dx=Math.abs(s-s0); if(dx==0) break;
        if(r>=2){if(dx<eps*(i+1+r*5)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        if(r>=3&&r<=5) 
                {var avg2=Math.abs((Math.LOG2E*Math.log(Math.abs((T[r][r-2]-T[r-1][r-2])/(T[r-1][r-2]-T[r-2][r-2])))));
                avg2+=Math.abs((Math.LOG2E*Math.log(Math.abs((T[r][r-3]-T[r-1][r-3])/(T[r-1][r-3]-T[r-2][r-3]))))); avg2*=0.5;
//              alert("Avg="+avg2+" r="+r);
                if(avg2<1.6&&avg2>1.4) q=1.5;   if(avg2<0.6&&avg2>0.4) q=0.5;   if(q!=0) break;
                }
        }
    if(q==0) return s;
    // Redo iteration using Fox_romberg with convergence power q
    this.reset();   this.method("Fox-Romberg");
    for(var r=0,i=1,s0=0,dx0=Number.POSITIVE_INFINITY;r<=max_r;dx0=dx,s0=s,r++,i*=2)
        {
        T[r]=new Array; 
        T[r][0]=tr?this.trapez(a,b,i):this.midtpoint(a,b,i); if(tr&&isFinite(T[r][0])==false) {tr=false; T[r][0]=this.midtpoint(a,b,i);}
        if(r>0){    T[r][1]=T[r][0]+(T[r][0]-T[r-1][0])/(Math.pow(2,q)-1);for(var j=2,pp=4;j<=r;j++,pp*=4){T[r][j]=T[r][j-1]+(T[r][j-1]-T[r-1][j-1])/(pp-1);}}
        s=T[r][r]; this.iteration(s);   dx=Math.abs(s-s0); if(dx==0) break; 
        if(r>=2){if(dx<eps*(i+1+r*5)*s&&this.q.length>3&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0); delete T;
    return s;
    }
// Integration Gauss Legendre Quadrature
Integration.prototype.gausslegendre=function(a,b)
    {
    this.gaussQuadDist=new Array;
    this.gaussQuadWeight=new Array;
    // Returns the distance (gaussQuadDist) and weight coefficients (gaussQuadCoeff) for an n point Gauss-Legendre Quadrature.
    // The Gauss-Legendre distances, gaussQuadDist, are scaled to -1 to 1
    function gaussQuadCoeff(o,n)
        {
        var z, z1, pp, p1, p2, p3, eps=Math.pow(2,-54)*10*n, x1=-1.0, x2=1.0;
        // Calculate roots. Roots are symmetrical - only half calculated
        var m=(n+1)/2, xm=0.5*(x2+x1), xl=0.5*(x2-x1);
        // Loop for  each root
        for(var i=1; i<=m; i++)
            {var it=0; z=Math.cos(Math.PI*(i-0.25)/(n+0.5));    // Approximation of ith root
            do{// Refinement on above using Newton's method
                p1=1.0; p2=0.0; it++;
                // Legendre polynomial (p1, evaluated at z, p2 is polynomial of one order lower) recurrence relationsip
                for(var j=1; j<=n; j++){p3=p2; p2=p1; p1=((2*j-1)*z*p2-(j-1)*p3)/j;}
                pp=n*(z*p1-p2)/(z*z-1);    // Derivative of p1
                z1=z; z=z1-p1/pp;            // Newton's method
            }while(Math.abs(z-z1)>eps&&it<6);
           if(it>=6) alert("Insuficient accuracy for Gauss Weight and Coefficients. Needed "+eps+" got "+Math.abs(z-z1));
            o.gaussQuadDist[i-1]=xm-xl*z;           // Scale root to desired interval
            o.gaussQuadDist[n-i]=xm+xl*z;           // Symmetric counterpart
            o.gaussQuadWeight[i-1]=2*xl/((1-z*z)*pp*pp);    // Compute weight
            o.gaussQuadWeight[n-i]=o.gaussQuadWeight[i-1];      // Symmetric counterpart
            }
        }
    
    // Numerical integration using n point Gaussian-Legendre quadrature (instance method)
    function gaussLegendre(o,a,b,n)
        {var sum=0.0, xplus=0.5*(Number(b)+Number(a)), xminus=0.5*(b-a);
      gaussQuadCoeff(o,n);// Calculate Gauss-Legendre coefficients, i.e. the weights and scaled distances
      for(var i=0; i<n; i++){var dx=xminus*o.gaussQuadDist[i]+xplus; sum+=o.gaussQuadWeight[i]*o.value(dx);}
      sum*=xminus; return sum;
        }

    var s, s0, dx0, dx, eps;
    if(a==b)return 0;   if(arguments.length==3) return gaussLegendre(this,a,b,arguments[2]); 
    eps=Math.pow(2,-54)*10; this.reset();    this.method("Gauss-Legendre");// Fixed n
    for(var i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=2048;dx0=dx,s0=s,i*=2)
        {
        s=gaussLegendre(this,a,b,i);
        dx=Math.abs(s-s0);  this.iteration(s); if(dx==0) break;
        if(this.i.length>2){if(dx<eps*(i*2+1)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);      
    return s;
   }
// Integration Gauss Chebyshev Quadrature
Integration.prototype.gausschebyshev=function(a,b)
    {
    // Numerical integration using n point Gaussian-Chebyshev quadrature 
    function gaussChebyshev(o,a,b,n)
        {var sum=0.0, xplus=0.5*(Number(b)+Number(a)), xminus=0.5*(b-a);
      for(var i=1; i<=n; i++){var dx=xminus*Math.cos((2*i-1)*Math.PI/(2*n))+xplus; sum+=Math.PI/n*o.value(dx)*Math.sqrt(1-dx*dx);}
      sum*=xminus; return sum;
        }

    var s, s0, dx0, dx, eps;
    if(a==b)return 0;   if(arguments.length==3) return gaussChebyshev(this,a,b,arguments[2]);
    eps=Math.pow(2,-54); this.reset();    this.method("Gauss-Chebyshev ");// Fixed n
    for(var i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=4096;dx0=dx,s0=s,i*=2)
        {
        s=gaussChebyshev(this,a,b,i);
        dx=Math.abs(s-s0);  this.iteration(s); if(dx==0) break;
        if(this.i.length>2){if(dx<eps*(i*6+1)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);      
    return s;
   }
// Integration Gauss Hermite Quadrature
Integration.prototype.gausshermite=function(a,b)
    {
    this.gaussQuadDist=new Array;
    this.gaussQuadWeight=new Array;
    // Returns the distance (gaussQuadDist) and weight coefficients (gaussQuadCoeff) for an n point Gauss-Legendre Quadrature.
    // The Gauss-Legendre distances, gaussQuadDist, are scaled to -1 to 1
    function gaussQuadCoeff(o,n)
        {
        var z, z1, pp, p1, p2, p3, eps=Math.pow(2,-54)*5*n, pim4=1/Math.pow(Math.PI,0.25), m=(n+1)/2;
        // Calculate roots. Roots are symmetrical - only half calculated
        for(var i=1; i<=m; i++)
            {// Approximation of ith root
             if(i==1) z=Math.sqrt(2*n+1)-1.85575*Math.pow(2*n+1,-0.16667); else
             if(i==2) z-=1.14*Math.pow(n,0.426)/z; else
             if(i==3) z=1.86*z-0.86*o.gaussQuadDist[0]; else
             if(i==4) z=1.91*z-0.91*o.gaussQuadDist[1]; else
             z=2*z-o.gaussQuadDist[i-3];

            var it=0; 
            do{// Refinement on above using Newton's method
                p1=pim4; p2=0.0; it++;
                for(var j=1; j<=n; j++){p3=p2; p2=p1; p1=z*Math.sqrt(2/j)*p2-Math.sqrt((j-1)/j)*p3;}
                pp=Math.sqrt(2*n)*p2;    // Derivative of p1
                z1=z; z=z1-p1/pp;            // Newton's method
                } while(Math.abs(z-z1)>eps&&it<10);
           if(it>=10&&Math.abs(z-z1)>eps) alert("Insuficient accuracy for Gauss Weight and Coefficients. Needed "+eps+" got "+Math.abs(z-z1));
            o.gaussQuadDist[i-1]=z;         // Store the root
            o.gaussQuadDist[n-i]=-z;        // Symmetric counterpart
            o.gaussQuadWeight[i-1]=2/(pp*pp);   // Compute weight
            o.gaussQuadWeight[n-i]=o.gaussQuadWeight[i-1];      // Symmetric counterpart
            }
        }
    
    // Numerical integration using n point Gaussian-Hermite quadrature
    function gaussHermite(o,a,b,n)
        {var sum=0.0;
      gaussQuadCoeff(o,n);// Calculate Gauss-Hermite coefficients, i.e. the weights and scaled distances
      for(var i=0; i<n; i++){var dx=o.gaussQuadDist[i]; sum+=o.gaussQuadWeight[i]*o.value(dx)/Math.exp(-dx*dx);} // Perform summation
        return sum;     // return value
        }

    var s, s0, dx0, dx;
    if(a==b)return 0;   if(arguments.length==3) return gaussHermite(this,a,b,arguments[2]); 
    eps=Math.pow(2,-54)*10; this.reset();   this.method("Gauss-Hermite");// Fixed n
    for(var i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=1024;dx0=dx,s0=s,i*=2)
        {
        s=gaussHermite(this,a,b,i);
        dx=Math.abs(s-s0);  this.iteration(s); if(dx==0) break;
        if(this.i.length>2){if(dx<eps*(i*5)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);      
    return s;
   }
   
// Integration Double Exponential
Integration.prototype.doubleexponential=function(a,b)
    {
    function DoubleExponential(o,a,b,n)
        {n/=2; var h=5.0/n; var ss=0.0;
        for(var k=-n;k<=n;k++)
            {var z=h*k; var exz=Math.exp(z); var hcos=exz+1.0/exz; var hsin=exz-1.0/exz; var s=Math.exp(Math.PI*hsin); var w=s+1.0/s; var x=(b*s+a/s)/w;
            if(x!=a&&x!=b) {var dxdz=2*(b-a)*Math.PI*hcos/(w*w); ss+=h*o.value(x)*dxdz; }
            //if(n==1) alert("x="+x);
            }
        //alert("["+a+";"+b+"]:"+n+"="+ss);
        return ss; 
        }

    var s, s0, dx0, dx, i, eps;
    if(a==b)return 0;   if(arguments.length==3) return DoubleExponential(this,a,b,arguments[2]); 
    eps=Math.pow(2,-54); this.reset();  this.method("DoubleExponential"); // Fixed n 
    for(i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=32768;dx0=dx,s0=s,i*=2)
        {s=DoubleExponential(this,a,b,i); 
        dx=Math.abs(s-s0);  this.iteration(s);  if(dx==0&&i!=1) break; 
        if(this.i.length>2){if(dx<eps*(i+1)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);      
    return s;
    }   
// Integration Double Exponential
Integration.prototype.doubleexponential2=function(a,b)
    {
    function DoubleExponential2(o,a,b,n)
        {n/=2; var h=5.0/n; var ss=0.5*o.value((Number(a)+Number(b))/2);
        for(var k=-n;k<0;k++)
            {var z=h*k; var exz=Math.exp(z); var hcos=exz+1.0/exz; var hsin=exz-1.0/exz; var s=Math.exp(Math.PI*hsin); var w=s+1.0/s; dxdz=hcos/(w*w); var x1=(b*s+a/s)/w;
            var x2=(a*s+b/s)/w; if(x1!=a&&x1!=b) {ss+=dxdz*o.value(x1);} if(x2!=a&&x2!=b) {ss+=dxdz*o.value(x2);}
            }
        //alert("["+a+";"+b+"]:"+n+"="+ss);
        return 2*(b-a)*Math.PI*h*ss;
        }

    var s, s0, dx0, dx, i, eps;
    if(a==b)return 0;   if(arguments.length==3) return DoubleExponential2(this,a,b,arguments[2]); 
    eps=Math.pow(2,-54); this.reset();  this.method("DoubleExponential2"); // Fixed n 
    for(i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=32768;dx0=dx,s0=s,i*=2)
        {s=DoubleExponential2(this,a,b,i); 
        dx=Math.abs(s-s0);  this.iteration(s);  if(dx==0&i!=1) break; 
        if(this.i.length>2){if(dx<eps*(i+1)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);      
    return s;
    }   
    
// Integration Double Exponential
Integration.prototype.doubleexponential3=function(a,b)
    {
    function DoubleExponential3(o,a,b,n)
        {n/=2; var h=5.0/n; var ss=0.0;
        for(var k=-n;k<=n;k++)
            {var z=h*k; var exz=Math.exp(z); var hcos=exz+1.0/exz; var hsin=exz-1.0/exz; var s=Math.exp(Math.PI*hsin); var w=s+1.0/s; var x=(b*s+a/s)/w;
            if(x!=a&&x!=b) {dxdz=hcos/(w*w); ss+=o.value(x)*dxdz;} 
            }
        if(n<32)alert("1st="+h*(b-a)*Math.PI*ss);
        var ss2=0.0;    
        for(k=-n;k<=n;k++)
            {var z=h*(Number(k)+0.5); var exz=Math.exp(z); var hcos=exz+1.0/exz; var hsin=exz-1.0/exz; var s=Math.exp(Math.PI*hsin); var w=s+1.0/s; 
            var x=(b*s+a/s)/w;
            if(n<32) if(isNaN(x)) alert("NaN in x s="+s+" w="+w+" hsin="+hsin+" exz="+exz+" z="+z+" h="+h+" n="+n+" k="+k);
            if(x!=a&&x!=b) {dxdz=hcos/(w*w); ss2+=o.value(x)*dxdz;}
            }
        if(n<32)alert("2nd="+h*(b-a)*Math.PI*ss2);
        if(isNaN(ss)) ss=0; if(isNaN(ss2)) ss2=0;
        return h*(b-a)*Math.PI*(ss+ss2);
        }

    var s, s0, dx0, dx, i, eps;
    if(a==b)return 0;   if(arguments.length==3) return DoubleExponential3(this,a,b,arguments[2]); 
    eps=Math.pow(2,-54); this.reset();  this.method("DoubleExponential3"); // Fixed n 
    for(i=1,s0=0,dx0=Number.POSITIVE_INFINITY;i<=32768;dx0=dx,s0=s,i*=2)
        {s=DoubleExponential3(this,a,b,i); 
        dx=Math.abs(s-s0);  this.iteration(s);  if(dx==0&&i!=1) break; 
        if(this.i.length>2){if(dx<eps*(i+1)*s&&this.q.length>1&&this.q[this.q.length-2]*0.85>this.q[this.q.length-1]) break;}
        }
    this.accuracy=Math.abs(2*dx).toExponential(0);      
    return s;
    }   
    
// Class Methods

// Class properties