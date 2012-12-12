/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2012 Scriptoid
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to
 * do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * @author Alex Gheorghiu <alex at scriptoid dot com>
 */


/**Add bezier to context*/
CanvasRenderingContext2D.prototype.bezier = bezier;

/**Draws a N grade bezier curve from current point on the context*/
function bezier(points){
    /**if set to true it will also paint debug information along with curve*/
    var debug = true;

    /**check for correct number of arguments*/
    if(points.length % 2 != 0 || points.length < 4){
        throw "Incorrect number of points " + points.length;
    }

    //simple console dump
    if(console){
      // console.info(points);
    }

    //transform initial arguments into an {Array} of [x,y] coordinates
    var initialPoints = [];
    for(var i=0;i<points.length; i=i+2){
        initialPoints.push([points[i], points[i+1]]);
    }

    function distance(a, b){
        return Math.sqrt(Math.pow(a[0]-b[0], 2) + Math.pow(a[1]-b[1], 2));
    }

    /**Computes the drawing/support points for the Bezier curve*/
    function computeSupportPoints(points){

        /**Computes factorial*/
        function fact(k){
            if(k==0 || k==1){
                return 1;
            }
            else{
                return k * fact(k-1);
            }
        }

        /**Computes Bernstain
        *@param {Integer} i - the i-th index
        *@param {Integer} n - the total number of points
        *@param {Number} t - the value of parameter t , between 0 and 1
        **/
        function B(i,n,t){
            //if(n < i) throw "Wrong";
            return fact(n) / (fact(i) * fact(n-i))* Math.pow(t, i) * Math.pow(1-t, n-i);
        }


        /**Computes a point's coordinates for a value of t
        *@param {Number} t - a value between o and 1
        *@param {Array} points - an {Array} of [x,y] coodinates. The initial points
        **/
        function P(t, points){
            var r = [0,0];
            var n = points.length-1;
            for(var i=0; i <= n; i++){
                r[0] += points[i][0] * B(i, n, t);
                r[1] += points[i][1] * B(i, n, t);
            }
            return r;
        }


        /**Compute the incremental step*/
        var tLength = 0;
        for(var i=0; i< points.length-1; i++){
            tLength += distance(points[i], points[i+1]);
        }
        var step = 1 / tLength;

        //compute the support points
        var temp = [];
        for(var t=0;t<=1; t=t+step){
            var p = P(t, points);
            temp.push(p);
        }
        return temp;
    }

    /**Simple function to display a "fat" dot*/
    function paintPoint(ctx, color,  point){
        //return;
        ctx.save();
        switch(color){
            case 'red':
                ctx.strokeStyle = "rgb(200, 0,0)";
                ctx.strokeRect(point[0]- 3 , point[1] - 3, 6, 6);
                break;

            case 'black':
                ctx.strokeStyle = "rgb(0, 0,0)";
                ctx.strokeRect(point[0]- 1 , point[1] - 1, 2, 2);
                break;

            case 'green':
                ctx.strokeStyle = "rgb(0, 200,0)";
                ctx.strokeRect(point[0]- 2 , point[1] - 2, 4, 4);
                break;
        }
        ctx.restore();
    }


    /**Paint the support points*/
    function paintPoints(ctx, points, color){
        ctx.save();

        //paint lines
        ctx.strokeStyle = '#CCCCCC';
        ctx.beginPath();
        ctx.moveTo(points[0][0], points[0][1]);
        for(var i=1;i<points.length; i++){
            ctx.lineTo(points[i][0], points[i][1]);
        }
        ctx.stroke();


        //controll points
        for(var i=0;i<points.length; i++){
            paintPoint(ctx, color, points[i]);
            ctx.fillText("P" + i + " [" + Math.round(points[i][0]) + ',' + Math.round(points[i][1]) + ']', points[i][0], points[i][1] - 10);
        }


        ctx.restore();
    }



    /**Generic paint curve method*/
    function paintCurve(ctx, points){
        ctx.save();

        ctx.beginPath();
        ctx.moveTo(points[0][0], points[0][1]);
        for(var i=1;i<points.length; i++){
            ctx.lineTo(points[i][0], points[i][1]);
        }
        ctx.stroke();
        ctx.restore();
    }

    var supportPoints = computeSupportPoints(initialPoints);
    paintCurve(this, supportPoints);
    if(debug){
        paintPoints(this, initialPoints, "red");
    }
}