App.guest = App.cable.subscriptions.create({ channel: "GuestChannel" }, {
    received(data) {
      console.log(data)
      console.log("yyy")
      switch (data.type){
        case 'crawler':
          this.crawler(data)
          break;
        case 'fail':
          Crawler.notify(data.msg, 'danger');
          break;
      }
    },

    crawler(data){
      Crawler.notify(data.msg, 'success');
      $(data.target).html(data.partial);
    }
});
    
