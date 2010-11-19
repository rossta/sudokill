beforeEach(function() {
  this.addMatchers({
    toHaveSelector: function(selector) {
      return this.actual.find(selector).length > 0;
    }
  });
});

var fixture = function() {
  return $("<div></div>").attr("id","sudokoup").appendTo("body");
},

removeFixture = function() {
  return $("#sudokoup").remove();
};
