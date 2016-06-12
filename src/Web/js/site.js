/*global $:false */
(function () {
	'use strict';

	var date = new Date().toJSON();
	$('.jumbotron').append($('<p>', {text:date}));
}());
