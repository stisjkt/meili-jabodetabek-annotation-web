var screenWidth = $(document).width();
var timeline = '<div id="timeline"><ul id="tl-list" class="timeline"></ul></div>';
if (screenWidth < 992) {
    $('#mySidenav').html(timeline);
} else {
    $('#left-panel').html(timeline);
}

$(window).on('resize', function () {
    var win = $(this); //this = window
    if ($(document).width() < 992) {
        $('#mySidenav').append($('#timeline'));
        $('#left-panel').empty();
    } else {
        $('#left-panel').append($('#timeline'));
        $('#mySidenav').empty();
    }
});

//fungsi openNav dan CloseNav untuk sidemenu
// function openNav() {
//     swal({
//         title: "Apakah segmentasi tripleg sudah selesai?",
//         text: "Selesaikan segmentasi triplegs sebelum mengisi detail perjalanan.",
//         icon: "warning",
//         buttons: {
//             cancel: "belum",
//             sudah: {
//                 text: "sudah",
//                 value: true
//             }
//         }
//     })
//         .then(function (value) {
//             if (value) {
//                 document.getElementById("mySidenav").style.width = "100%";
//
//                 var open = document.getElementById("open");
//                 if (open !== null) {
//                     open.style.display = "none";
//                 }
//
//                 var close = document.getElementById("close");
//                 if (close !== null) {
//                     close.style.display = "block";
//                 }
//
//                 Android.doEvent("openNav");
//             } else {
//                 closeNav();
//             }
//         });
// }
//
// function closeNav() {
//     document.getElementById("mySidenav").style.width = "0";
//
//     var open = document.getElementById("open");
//     if (open !== null) {
//         open.style.display = "block";
//     }
//
//     var close = document.getElementById("close");
//     if (close !== null) {
//         close.style.display = "none";
//     }
//
//     Android.doEvent("closeNav");
// }

function logout() {
    $.removeCookie('_ga', {
        path: '/'
    });
    $.removeCookie('_gat', {
        path: '/'
    });
    $.removeCookie('_gid', {
        path: '/'
    });
    $.cookie("connect.sid", 1, {
        expires: -1,
        path: '/'
    });

    /*    document.cookie = "_ga" + '=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
        document.cookie = "_gat" + '=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
        document.cookie = "_gid" + '=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
        document.cookie = "connect.sid" + '=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';*/

    /*
      var cookies = document.cookie.split(";");
      console.log(cookies);
      for(var i=0; i<cookies.length ; i++){
      var cookie = cookies[i];
      var eqPos = cookie.indexOf("=");
      var name = eqPos > -1 ? cookie.substr(0,eqPos) : cookie;
      console.log(name);
      document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 GMT";
      }
      location.reload();
  */
}

$("#right-nav").html("<li id='badge_holder'>"+
  "<a href='/map'>Sisa Trip<span class='badge' id='tripsLeft' data-toggle='collapse' data-target='.navbar-collapse.show'></span></a></li>"+
  "<li id='logout-button'>"+
  "<a href='#' onclick='logout();' data-toggle='collapse' data-target='.navbar-collapse.show'>Logout</a></li>");


function loadingOverlay() {
    $.LoadingOverlay("show");
    setTimeout(function () {
        $.LoadingOverlay("hide");
    }, 2000);
}