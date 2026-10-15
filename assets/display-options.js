// Display options: colours off, larger text, images off.
// Each button toggles a class on <html>; the choice is remembered on this device.
// Without JavaScript the bar stays hidden and the site works normally.
(function () {
  var root = document.documentElement;
  var bar = document.getElementById("display-bar");
  if (!bar) return;

  function saved() {
    try { return JSON.parse(localStorage.getItem("display-options") || "[]"); } catch (e) { return []; }
  }
  function save() {
    var on = [];
    bar.querySelectorAll("button[data-option]").forEach(function (b) {
      if (root.classList.contains(b.dataset.option)) on.push(b.dataset.option);
    });
    try { localStorage.setItem("display-options", JSON.stringify(on)); } catch (e) {}
  }

  // With images off, show each image's description in its place.
  document.querySelectorAll("main img[alt]").forEach(function (img) {
    if (!img.alt) return;
    var text = document.createElement("span");
    text.className = "img-alt";
    text.textContent = img.alt;
    var target = img.parentNode.tagName === "A" ? img.parentNode : img;
    target.parentNode.insertBefore(text, target.nextSibling);
  });

  saved().forEach(function (o) { root.classList.add(o); });
  bar.querySelectorAll("button[data-option]").forEach(function (b) {
    b.setAttribute("aria-pressed", root.classList.contains(b.dataset.option) ? "true" : "false");
    b.addEventListener("click", function () {
      var on = root.classList.toggle(b.dataset.option);
      b.setAttribute("aria-pressed", on ? "true" : "false");
      save();
    });
  });
  bar.hidden = false;
})();
