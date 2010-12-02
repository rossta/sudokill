var fixture = function() {
  return $("<div></div>").attr("id","sudocoup").css({
    position:"absolute",left:"-3000px",top:"0px"
  }).appendTo("body");
},

removeFixture = function() {
  return $("#sudocoup").remove();
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
