part of dartifact;

HtmlElement createSimpleNotificationElement({ roles: "simple_notification", and: null, attr_properties: null, attrs: null}) {

  if(attr_properties == null)
    attr_properties = [
     "container_name:data-container-name",
     "permanent:data-permanent",
     "autohide_delay:data-autohide-delay",
    ].join(",");

  return createDomEl("SimpleNotificationComponent", roles: roles, attrs: attrs, attr_properties: attr_properties, and: (el) {
    return[
      createDomEl("", property: "message"),
      createDomEl("", part: "close"),
    ];
  });

}

Component createSimpleNotificationComponent({ roles: "simple_notification", attrs: null, and: null, parent: null }) {
  var el = createSimpleNotificationElement(roles: roles, attrs: attrs);
  var component = createComponent("SimpleNotificationComponent", el: el, and: and, parent: parent);
  return component;
}
