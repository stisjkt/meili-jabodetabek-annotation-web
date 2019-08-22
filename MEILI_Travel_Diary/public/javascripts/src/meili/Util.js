
var Util = function(config) {
  return {
    formatTime: function(strDateTime, format) {
      var dateTime;
      if(strDateTime && strDateTime !== '') {
        var dateTimeInt = parseInt(strDateTime,10);
        dateTime = new Date(dateTimeInt);
        if(format) {
          dateTime = moment(dateTime).format(format);
        }
      }
      return dateTime;
    },

    sortByAccuracy: function(array) {
      if($.isArray(array)) {
        return array.sort(
          function(a, b) {
            if (a.accuracy < b.accuracy) {
              return 1;
            }

            if (a.accuracy > b.accuracy) {
              return -1;
            }

            if (a.name > b.name) {
              return 1;
            }

            return -1;
          });
      } else {
        return array;
      }
    }, 
	
	sortByName: function(array) {
      if($.isArray(array)) {
        return array.sort(
          function(a, b) {
            if (a.name > b.name) {
              return 1;
            } else {
			  return -1;
			}
            return -1;
          });
      } else {
        return array;
      }
    },
	
	isPreviewMode: function() {
        var regexS = "[\\?&]previewMode=([^&#]*)";
        var regex = new RegExp(regexS);
        var results = regex.exec(window.location.href);
        if (results == null)
            return false;
        else
            return decodeURIComponent(results[1].replace(/\+/g, " ")) === 'true';
    }
  }
};