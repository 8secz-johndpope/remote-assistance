// SAR (ScreenAR)

let skinDetected = false;
let fxcanvas = fx.canvas();

let sarcanvas = document.createElement('canvas');
var sarcanvasw = 480;
var sarcanvash = 320;
sarcanvas.width = sarcanvasw;
sarcanvas.height = sarcanvash;
var sarctx = sarcanvas.getContext('2d');

var correctedcanvas = document.getElementById('correctedcanvas');
correctedcanvas.width = sarcanvasw;
correctedcanvas.height = sarcanvash;
var correctedctx = correctedcanvas.getContext('2d');
document.body.appendChild(correctedcanvas);

correctedctx.fillStyle = 'gray';
correctedctx.fillRect(0,0,sarcanvasw,sarcanvash);

correctedcanvas.addEventListener('click',function (evt) {
    evt.preventDefault();
    evt.stopPropagation();
    let x = evt.pageX;
    let y = evt.pageY;
    x -= correctedcanvas.offsetLeft;
    y -= correctedcanvas.offsetTop;
    x = (x * 100 / correctedcanvas.offsetWidth) | 0;
    y = (y * 100 / correctedcanvas.offsetHeight) | 0;
    console.log(x,y);
    if (wrtc && wrtc.sendChannel)
      wrtc.sendChannel.send(`${x},${y},text`);
    else
      console.error('no wrtc.sendChannel for sending click',x,y);
});

function OneEuroFilter(freq, mincutoff, beta, dcutoff){
	var that = {};
	var x = LowPassFilter(alpha(mincutoff));
	var dx = LowPassFilter(alpha(dcutoff));
	var lastTime = undefined;
	
	mincutoff = mincutoff || 1;
	beta = beta || 0;
	dcutoff = dcutoff || 1;
	
	function alpha(cutoff){
		var te = 1 / freq;
		var tau = 1 / (2 * Math.PI * cutoff);
		return 1 / (1 + tau / te);
	}
	
	that.filter = function(v, timestamp){
		if(lastTime !== undefined && timestamp !== undefined)
			freq = 1 / (timestamp - lastTime);
		lastTime = timestamp;
		var dvalue = x.hasLastRawValue() ? (v - x.lastRawValue()) * freq : 0;
		var edvalue = dx.filterWithAlpha(dvalue, alpha(dcutoff));
		var cutoff = mincutoff + beta * Math.abs(edvalue);
		return x.filterWithAlpha(v, alpha(cutoff));
	}
	
	return that;
}

function LowPassFilter(alpha, initval){
	var that = {};
	var y = initval || 0;
	var s = y;
	
	function lowpass(v){
		y = v;
		s = alpha * v + (1 - alpha) * s;
		return s;
	}
	
	that.filter = function(v){
		y = v;
		s = v;
		that.filter = lowpass;
		return s;
	}
	
	that.filterWithAlpha = function(v, a){
		alpha = a;
		return that.filter(v);
	}
	
	that.hasLastRawValue = function(){
		return that.filter === lowpass;
	}
	
	that.lastRawValue = function(){
		return y;
	}
	
	return that;
}

var freq = 30;
var filterx = OneEuroFilter(freq, 1, 0.01, 1);
var filtery = OneEuroFilter(freq, 1, 0.01, 1);

function sarAnimate(scopeCanvas2d)
{
  let ctx = scopeCanvas2d.getContext('2d');
  if (sarcanvas.width !== scopeCanvas2d.width || sarcanvas.height !== scopeCanvas2d.height)
  {
    console.log('sarAnimate: setting w, h',scopeCanvas2d.width,scopeCanvas2d.height);
    sarcanvasw = scopeCanvas2d.width;
    sarcanvash = scopeCanvas2d.height;

    sarcanvas.width = sarcanvasw;
    sarcanvas.height = sarcanvash;

    fxcanvas = fx.canvas();
    fxcanvas.width = sarcanvasw;
    fxcanvas.height = sarcanvash;

  }
  sarctx.drawImage(video,0,0,sarcanvasw,sarcanvash);
  let corners = detectCorners(sarctx);
  if (corners !== null)
  {
    correctedcanvas.style.opacity = 1;
    let texture = fxcanvas.texture(sarcanvas);
    fxcanvas.draw(texture).perspective(
      [
        corners.tl.x,corners.tl.y,
        corners.tr.x,corners.tr.y,
        corners.br.x,corners.br.y,
        corners.bl.x,corners.bl.y],
      [
        0,0,
        sarcanvasw,0,
        sarcanvasw,sarcanvash,
        0,sarcanvash]).update();
    correctedctx.drawImage(fxcanvas,0,0,correctedcanvas.width,correctedcanvas.height);
    if (skinDetected)
    {
      correctedctx.fillStyle = 'yellow';
      correctedctx.font = '24px Arial';
      correctedctx.fillText('HAND',40,40);
    }
    let fingerPosition = detectFingerTip(correctedctx.getImageData(0,0,correctedcanvas.width,correctedcanvas.height));
    if (fingerPosition)
    {
      correctedctx.fillStyle = 'red';
      correctedctx.beginPath();
      correctedctx.ellipse(fingerPosition.x,fingerPosition.y,8,8,0,0,2*Math.PI);
      correctedctx.fill();
    }
    scopeCanvas2d.getContext('2d').drawImage(video,16,16,scopeCanvas2d.width-32,scopeCanvas2d.height-32,0,0,scopeCanvas2d.width,scopeCanvas2d.height);
  }
  else
    correctedcanvas.style.opacity = 0.1;
}

function detectFingerTip(imgData) {
  let data = imgData.data;
  let canvasw = imgData.width;
  let canvash = imgData.height;
  let idx = 0;
  let miny = -1;
  let rows = {};
  let minx = canvasw;
  let maxx = 0;
  for (let y=0;y<canvash;y++)
  {
    for (let x=0;x<canvasw;x++)
    {
      if (data[idx] < 100 && data[idx+1] >= 250 && data[idx+2] < 100)
      {
        if (rows[y])
        {
          rows[y].min = Math.min(x,rows[y].min)
          rows[y].max = Math.max(x,rows[y].max)
        }
        else
        {
          rows[y] = {min:x,max:x};
        }
      }
      idx += 4;
    }
  }
  let middlex = 0;
  let nmiddle = 0;
  let meanwidth = 0;
  let top = -1;
  for (let y in rows)
  {
    let row = rows[y];
    if (row.max - row.min > 50)
    {
      if (top === -1)
        top = +y;
      middlex += (row.max + row.min) / 2;
      nmiddle++;
      meanwidth += row.max - row.min;
      //ctxtip.fillRect(row.min,y,row.max-row.min,1);
    }
    if (nmiddle > 10)
      break;
  }
  if (nmiddle >= 10)
  {
    middlex /= nmiddle;
    //var timestamp = (1.0 / freq) * i;
		var filteredx = filterx.filter(middlex);
		var filteredy = filtery.filter(top);

    /*ctx.fillStyle = 'red';
    ctx.beginPath();
    ctx.ellipse(filteredx,filteredy,8,8,0,0,2*Math.PI);
    ctx.fill();*/
    return {x:filteredx, y: filteredy};
  }
  else
    return null;
}

var dataChannelCallback = function(data) {
  console.log('dataChannelCallback data=',data);
  if (data === 'skin')
  {
    clearTimeout(skinTimeout);
    skinDetected = true;
    console.error('skin detected');
    skinTimeout = setTimeout(function () { skinDetected = false; },30);
    return;
  }
  let anchorSize = [];
  data.split(',').forEach(i => anchorSize.push(parseInt(i)));
  let anchorWidth = anchorSize[0];
  let anchorHeight = anchorSize[1];
  let newWidth = 640;
  let newHeight = ((640 * anchorHeight) / anchorWidth) | 0;
  if (correctedcanvas.width !== newWidth || correctedcanvas.height !== newHeight)
  {
    correctedcanvas.width = newWidth;
    correctedcanvas.height = newHeight;
    console.log('correctedcanvas width/height=',correctedcanvas.width,correctedcanvas.height);
  }
}

function detectCorners(ctx)
{
  let canvasw = ctx.canvas.width;
  let canvash = ctx.canvas.height;
  if (canvasw === 0 || canvash === 0)
  {
    return null;
  }
  
  let imgData = ctx.getImageData(0,0,canvasw,canvash);
  let data = imgData.data;
  let idx = 0;
  
  // top gives x positions of tl and tr corners
  let tl = {x:-1,y:-1};
  const th = 200;
  for (let i=0;i<canvasw;i++)
  {
    if (data[idx] >= th && data[idx+1] >= th && data[idx+2] >= th)
    {
      tl.x = i;
      break;
    }
    idx += 4;
  }

  let tr = {x:-1,y:-1};
  idx = 4 * canvasw - 4;
  for (let i=canvasw;i>=0;i--)
  {
    if (data[idx] >= th && data[idx+1] >= th && data[idx+2] >= th)
    {
      tr.x = i;
      break;
    }
    idx -= 4;
  }

  // bottom gives x positions of bl and br corners
  let bl = {x:-1,y:-1};
  idx = ((canvash - 1) * canvasw * 4);
  for (let i=0;i<canvasw;i++)
  {
    if (data[idx] >= th && data[idx+1] >= th && data[idx+2] >= th)
    {
      bl.x = i;
      break;
    }
    idx += 4;
  }

  let br = {x:-1,y:-1};
  idx = (canvash * canvasw * 4) - 4;
  for (let i=canvasw;i>=0;i--)
  {
    if (data[idx] >= th && data[idx+1] >= th && data[idx+2] >= th)
    {
      br.x = i;
      break;
    }
    idx -= 4;
  }
  
  // left gives y positions of tl and bl corners
  idx = 0;
  for (let i=0;i<canvash;i++)
  {
    if (data[idx] >= th && data[idx+1] >= th && data[idx+2] >= th)
    {
      tl.y = i;
      break;
    }
    idx += canvasw * 4;
  }

  idx = ((canvash - 1) * canvasw * 4);
  for (let i=canvash;i>=0;i--)
  {
    if (data[idx] >= th && data[idx+1] >= th && data[idx+2] >= th)
    {
      bl.y = i;
      break;
    }
    idx -= canvasw * 4;
  }

  // right gives y positions of tr and br corners
  idx = canvasw * 4 - 4;
  for (let i=0;i<canvash;i++)
  {
    if (data[idx] >= th && data[idx+1] >= th && data[idx+2] >= th)
    {
      tr.y = i;
      break;
    }
    idx += canvasw * 4;
  }

  idx = (canvash * canvasw * 4) - 4;
  for (let i=canvash;i>=0;i--)
  {
    if (data[idx] >= th && data[idx+1] >= th && data[idx+2] >= th)
    {
      br.y = i;
      break;
    }
    idx -= canvasw * 4;
  }

  let ok = true;
  [tl,tr,bl,br].forEach(pt => ok &= goodPoint(pt));
  if (ok)
    return {tl:tl,tr:tr,bl:bl,br:br};
  else
    return null;
}

function goodPoint(pt)
{
  return pt.x !== -1 && pt.y !== -1;
}

var sar = {
  animate: function (canvas) {
    if (!window.enableScreenAR) {
      return;
    }
    //console.log('sar animate');
    sarAnimate(canvas);
  },
}