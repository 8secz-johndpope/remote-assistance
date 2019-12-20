/// <reference path="../wakingapp.d.ts" />
var dir = -1;
function start() 
{ 

}

function update(deltaTime) 
{ 
    object.transform.rotate(dir * 15 * deltaTime, Vector3.up);
}

function onTargetFound(id) 
{ 

}

function onTargetLost(id) 
{ 

}

function onTouchStarted()
{
}

function onTouchEnded()
{
    dir == 1 ? dir = -1 : dir = 1
}

function onEnabled() 
{ 

}

function onDisabled() 
{ 

}

