var Login = Login || function(user) {

  this.user = user;

  this.addListeners();

  Emitter(this);

  return this;
}

Login.prototype = {
  addListeners: function() {

      if(localStorage) {
          if (localStorage.username && localStorage.pass != '') {
              if (localStorage.chkbox != '') {
                  //kondisi remember me dan sudah logout
                  this.user.login(localStorage.username, localStorage.pass)
                      .done(function () {
                          page('/map?previewMode=true');
                      });
              }
          }
      }

    $('body').on('submit', '.form-signin', function(e) {
      var input = $(e.target).serializeArray();
      if(!input[0] && input[0].value === '') {
        throw 'No username provided';
        return;
      }
      if(!input[1] && input[1].value === '') {
        throw 'No password provided';
        return;
      }


      this.user.login(input[0].value, input[1].value)

        .done(function() {

      if ($('#remember').is(':checked')) {
            // save username and password
            localStorage.username = $('#email').val();
            localStorage.pass = $('#pw').val();
            localStorage.chkbox = $('#remember').val();
        } else {
            localStorage.username = '';
            localStorage.pass = '';
            localStorage.chkbox = '';
      };
          page('/map?previewMode=true');
        })
      //  .fail(function() { page('/login'); });
      .fail(function() { page('/login'); });

      e.preventDefault();
    }.bind(this));
  }
};

