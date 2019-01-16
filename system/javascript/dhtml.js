// dhtml.js
// cross-platform dhtml javascript functions
// for mozilla, explorer 5+
//
// author: philetus@u.washington.edu
//
// functions:
//  getWindowWidth(): returns width of window in pixels
//  getWindowHeight(): returns height of window in pixels
//  getDivByID( id ): returns div with the specified id
//  getDivWidth( id ): returns width of div with the specified id
//  getDivHeight( id ): returns height of div with the specified id
//  getDivLeft( id ): returns distance from the left edge of the 
//                    window in pixels of div with the specified id
//  getDivTop( id ): returns distance from the top edge of the 
//                   window in pixels of div with the specified id
//  moveDivBy( id, left, top ): move div with the specified id by
//                              left pixels to the right and top
//                              pixels down
//  moveDivTo( id, left, top ): move div with the specified id to
//                              left pixels from the left and top
//                              pixels from the top
//  getImage( imgName, id ): returns the image named imgName, in
//                           the div specified by id
//                           (do not provide an id if the image is
//                           not in a div)
//  swapImage( imgName, swapSrc, id ): replaces the image named 
//                                     imgName with swapSrc
//                                     (id is only necessary if
//                                     the image is in a div)
//  swapBack(): restores the last image swapped with swapImage
//  writeToDiv( id, html ): replaces contents of div with html

////////////////////////////////////////////
// determine browser: 
if( document.all ) {
	browser = 2; // explorer 3+
} else if( document.getElementById ) {
	browser = 1; // netscape 5+ (mozilla)
} else { 
	browser = 0; // other
}

////////////////////////////////////////////
function getWindowWidth() {
	if( browser == 1 ) {
		return window.innerWidth;
	} else if( browser == 2 ) {
		return document.body.clientWidth;
	} else {
		return null;
	}
}

////////////////////////////////////////////
function getWindowHeight(){
	if( browser == 1 ) {
		return window.innerHeight;
	} else if( browser == 2 ) {
		return document.body.clientHeight;
	} else {
		return null;
	}
}

////////////////////////////////////////////
function getDivByID( id ) {
	if( browser == 1 ) {
		return document.getElementById( id );
	} else if( browser == 2 ) {
		return eval( id );
	} else {
		return null;
	}
}

////////////////////////////////////////////
function getDivWidth( id ) {
	var div = getDivByID( id );
	if( browser == 1 || browser == 2 ) {
		return parseInt( div.style.width );
	} else {
		return null;
	}
}

////////////////////////////////////////////
function getDivHeight( id ) {
	var div = getDivByID( id );
	if( browser == 1 || browser == 2 ) {
		return parseInt( div.style.height );
	} else {
		return null;
	}
}

////////////////////////////////////////////
function getDivLeft( id ) {
	var div = getDivByID( id );
	if( browser==1 || browser==2 ) {
		return parseInt(div.style.left);
	} else {
		return null;
	}
}

////////////////////////////////////////////
function getDivTop( id ) {
	var div = getDivByID( id );
	if( browser==1 || browser==2 ) {
		return parseInt( div.style.top );
	} else {
		return null;
	}
}

////////////////////////////////////////////
function moveDivBy( id, left, top ) {
	var div = getDivByID( id );
	if( browser==1 || browser==2 ) {
		div.style.left = parseInt( div.style.left ) + left;
		div.style.top = parseInt( div.style.top ) + top;
		return;
	} else {
		return null;
	}
}

////////////////////////////////////////////
function moveDivTo( id, left, top ) {
	var div = getDivByID( id );
	if( browser==1 || browser==2 ) {
		div.style.left=left;
		div.style.top=top;
		return;
	} else {
		return null;
	}
}

////////////////////////////////////////////
function getImage( imgName, id ) {
	if( browser==1 ) {
		return document.images[imgName];
	} else if( browser==2 ) {
		return document.images( imgName );
	} else {
		return null;
	}
}

////////////////////////////////////////////
function swapImage( imgName, swapSrc, id ) {
	backImg = getImage( imgName, id );
	backSrc = backImg.src;
	backImg.src = swapSrc;
}

////////////////////////////////////////////
function swapBack() {
	backImg.src = backSrc;
}

////////////////////////////////////////////
function writeToDiv( id, html ) {
	var div = getDivByID( id );
	if( browser==1 || browser==2 ) {
		div.innerHTML = html;
	} else {
		return null;
	}
}
