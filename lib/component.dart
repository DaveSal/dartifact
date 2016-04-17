part of nest_ui;

class Component extends Object with observable.Subscriber,
                                    observable.Publisher,
                                    HeritageTree,
                                    Attributable
{

  /* Events emitted by the browser that we'd like to handle
  *  if you prefer to not listen to them all for your component,
  *  simply list the ones you'd like to listen to, ommiting all the others.
  *
  *  native_events_list is a variable defined in native_events_list.dart
  *  and it simply contains a List of all events Dart is capable of catching.
  *  If you'd like to listen to all of those native events, uncomment it and assign
  *  native_events to it, however not that it might affect performance.
  */
  List native_events = []; // native_events_list;

  // a DOM element associated with this component
  HtmlElement _dom_element;

  // ... and you can add more, for example [... ButtonBehaviors, LinkBehaviors] 
  List behaviors  = [BaseComponentBehaviors];
  // instantiated behavior objects, don't touch it
  List _behaviors = [];

  final Map attribute_callbacks = {
    'default' : (attr_name, self) => self.prvt_updatePropertyOnNode(attr_name)
  };

  get dom_element => _dom_element;
  set dom_element(HtmlElement el) {
    _dom_element = el;
    _listenToNativeEvents();
  }
  
  Component() {
    _createBehaviors();
  }

  behave(behavior) {
    _behaviors.forEach((b) {
      if(methods_of(b).contains(behavior)) {
        var im = reflect(b);
        im.invoke(new Symbol(behavior), []);
        return;
      }
    });
  }

  initChildComponents() {
    var elements = _findChildComponentDomElements(this.dom_element);
    elements.forEach((el) {
      ['', 'nest_ui'].forEach((l) {
        var component = new_instance_of(el.getAttribute('data-component-class'), l);
        if(component != null) {
          component.dom_element = el;
          this.addChild(component);
        }
      });
    });
  }

  // Updates dom element's #text or attribute so it refelects Component's current property value.
  prvt_updatePropertyOnNode(property_name) {
    var property_el = _firstDescendantOrSelfWithAttr(
        this.dom_element,
        attr_name: "data-component-property",
        attr_value: property_name
    );
    if(property_el != null) {
      /// Basic case when property is tied to the node's text.
      property_el.text = this.attributes[property_name];
      /// Now deal with properties tied to an element's attribute, rather than it's text.
      _updatePropertyOnHtmlAttribute(property_el, property_name);
    }
  }

  _listenToNativeEvents() {
    this.native_events.forEach((e) {
      /// Event belongs to an html element which is a descendant of our component's dom_element
      if(e.contains('.')) {
        e = e.split('.'); // the original string is something like "text_field.click"
        var part_name  = e[0];
        var event_name = e[1];
        var part_el   = _firstDescendantOrSelfWithAttr(
            this.dom_element,
            attr_name: 'data-component-part',
            attr_value: part_name
        );
        if(part_el != null) {
          part_el.on[event_name].listen((e) => this.captureEvent(e.type, ["self.$part_name"]));
        }
      }
      /// Event belongs to our component's dom_element
      else {
        this.dom_element.on[e].listen((e) => this.captureEvent(e.type, [#self]));
      }
   }); 
  }

  _createBehaviors() {
    behaviors.forEach((b) {
      ['', 'nest_ui'].forEach((l) {
        var behavior_instance = new_instance_of(b.toString(), l);
        if(behavior_instance != null) {
          behavior_instance.component = this;
          _behaviors.add(behavior_instance);
        }
      });
    });
  }

  _updatePropertyOnHtmlAttribute(node, attr_name) {
    var property_html_attr_name = node.getAttribute('data-component-property-attr-name');
    if(property_html_attr_name != null)
      node.setAttribute(property_html_attr_name, this.attributes[attr_name]);
  }

  // Finds first DOM descendant with a certain combination of attribute and its value,
  // or returns the same node if that node has that combination.
  _firstDescendantOrSelfWithAttr(node, { attr_name: null, attr_value: null }) {

    if(attr_name == null || node.getAttribute(attr_name) == attr_value)
      return node;
    else if(node.children.length == 0)
      return null;

    var el;
    node.children.forEach((c) {
      if(c.getAttribute('data-component-id') == null) {
         el = _firstDescendantOrSelfWithAttr(c, attr_name: attr_name, attr_value: attr_value);
      }
    });

    return el;

  }

  _findChildComponentDomElements(node) {
    List component_children = [];
    node.children.forEach((c) {
      if(c.getAttribute('data-component-class') == null)
        component_children.addAll(_findChildComponentDomElements(c));
      else
        component_children.add(c);
    });
    return component_children;
  }

  // So far this is only required for Attributable module to work on this class.
  noSuchMethod(Invocation i) {  
    try {
      return prvt_noSuchGetterOrSetter(i);
    } on NoSuchAttributeException {
      super.noSuchMethod(i);
    }
  }

}
