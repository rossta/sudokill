try {
  window.console.log.apply(window.console, ["Tests running..."]);
} catch(e) {
  window.console = {
    log: function() {}
  };
}

var fixture = function() {
  return $("<div></div>").attr("id","sudokill").css({
    position:"absolute",left:"-3000px",top:"0px"
  }).appendTo("body");
},

removeFixture = function() {
  return $("#sudokill").remove();
};

beforeEach(function() {
  this.addMatchers({
    toHaveSelector: function(selector) {
      return this.actual.find(selector).length > 0;
    },
    toHaveLength: function(length) {
      return this.actual.length == length;
    },
    toBeVisible: function() {
      return this.actual.is(":visible");
    },
    toHaveClass: function(className) {
      return this.actual.hasClass(className);
    }
  });
  fixture();
});
afterEach(removeFixture);
