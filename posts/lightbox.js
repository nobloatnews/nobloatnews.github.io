/* lightbox.js
   Convierte los enlaces <a href="imagen.jpg"><img ...></a> en un visor de
   pantalla completa que NO navega a otra URL. Como nunca cambia la barra
   de direcciones, evita el aviso de "sitio peligroso" que muestran algunos
   navegadores de smart TV con certificados desactualizados.

   Uso: agregar en cada pagina, antes de </body>:
     <script src="../lightbox.js" defer></script>
   (ajustar la ruta "../" segun donde este el archivo respecto a la pagina,
   igual que hacen con ../style.css)
*/
(function () {
  function esEnlaceDeImagen(href) {
    return /\.(jpe?g|png|gif|webp)(\?.*)?$/i.test(href || "");
  }

  function iniciar() {
    // Crea el overlay una sola vez
    var overlay = document.createElement("div");
    overlay.id = "lightbox-overlay";
    overlay.innerHTML =
      '<span id="lightbox-close">&times;</span>' +
      '<img id="lightbox-img" alt="">';
    document.body.appendChild(overlay);

    var overlayImg = document.getElementById("lightbox-img");

    function abrir(src) {
      overlayImg.src = src;
      overlay.classList.add("active");
    }
    function cerrar() {
      overlay.classList.remove("active");
      overlayImg.src = "";
    }

    overlay.addEventListener("click", cerrar);
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") cerrar();
    });

    // Intercepta todos los <a> que envuelven una <img> y apuntan a un archivo de imagen
    document.querySelectorAll("a").forEach(function (a) {
      var img = a.querySelector("img");
      if (img && esEnlaceDeImagen(a.getAttribute("href"))) {
        a.addEventListener("click", function (e) {
          e.preventDefault();
          abrir(a.getAttribute("href"));
        });
      }
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", iniciar);
  } else {
    iniciar();
  }
})();
