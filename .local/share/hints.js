const characters = "fdsagrewcx";
const id = "gcpccpgdkmihefbjbhkipbjcpfaokokd-hints";

const queryElements = () => {
  const elements = document.querySelectorAll(
    'a, button, input:not([type="hidden"]), select, textarea',
  );
  const visibleElements = [...elements].filter((element) =>
    elementVisible(element),
  );
  return visibleElements;
};

const hideHints = () => {
  const element = document.getElementById(id);
  element.remove();
};

const elementVisible = (element) => {
  const [{ bottom, top } = {}] = element.getClientRects();
  const visible = bottom >= 0 && top <= innerHeight;
  return visible;
};

const clickElement = (element, newTab = false) => {
  const { target } = element;
  if (element.target === "_blank") {
    element.removeAttribute("target");
  }

  const event = new MouseEvent("click", {
    bubbles: true,
    cancelable: true,
    ctrlKey: newTab,
    view: window,
  });
  element.dispatchEvent(event);

  element.target = target;

  if (elementVisible(element)) {
    element.focus({ preventScroll: true });
  }
};

const listenHintsEvents = (hints, labels) => {
  hints.addEventListener("click", () => {
    hideHints();
  });

  addEventListener(
    "scroll",
    () => {
      hideHints();
    },
    { once: true },
  );

  let input = "";
  hints.addEventListener("keydown", (event) => {
    event.preventDefault();
    event.stopPropagation();

    const character = event.key.toLowerCase();
    if (characters.includes(character)) {
      input += character;

      const [label = ""] = Object.keys(labels);
      if (input.length > label.length) {
        hideHints();
      } else {
        const element = labels[input];
        if (element) {
          clickElement(element, event.shiftKey);
          hideHints();
        }
      }
    } else if (event.key !== "Shift") {
      hideHints();
    }
  });
};

const showHints = () => {
  const labels = {};

  const hints = document.createElement("div");
  hints.id = id;
  hints.tabIndex = 0;

  const elements = queryElements();
  for (const [index, element] of Object.entries(elements)) {
    const { length } = elements.length.toString();
    const numericLabel = index.toString().padStart(length, "0");
    const label = [...numericLabel].map((digit) => characters[digit]).join("");

    labels[label] = element;

    const hint = document.createElement("span");
    hint.dataset.label = label;
    const [{ left, top }] = element.getClientRects();
    hint.style.left = `${left}px`;
    hint.style.top = `${top}px`;
    hint.textContent = label.toUpperCase();
    hints.appendChild(hint);
  }

  const style = document.createElement("style");
  style.textContent = `
  #${id} {
    position: fixed;
    inset: 0;
    z-index: 2147483647;
    overflow: hidden;
  }

  #${id}:focus {
    outline: none;
  }

  #${id} > * {
    position: absolute;
    margin: 0;
    padding: 0;
    background-color: white;
    color: black;
    font: 16px / 1.2 monospace;
  }
  `.replace(/;/g, " !important$&");
  hints.appendChild(style);

  document.body.append(hints);

  hints.focus();
  listenHintsEvents(hints, labels);
};

const main = () => {
  addEventListener("keydown", (event) => {
    if (!event.altKey || !event.ctrlKey || event.key !== "f") return;

    event.preventDefault();
    event.stopPropagation();

    showHints();
  });
};

main();
