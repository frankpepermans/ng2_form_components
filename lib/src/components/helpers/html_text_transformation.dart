library ng2_form_components.helpers.html_text_transformation;

import 'dart:async';
import 'dart:html';

typedef Future<HTMLTextTransformation> AsyncTransformation();

class HTMLTextTransformation {

  final String tag;
  final String label;
  final Map<String, String> style;
  final Map<String, String> attributes;
  final String id;
  final String className;
  final bool allowRemove;
  final AsyncTransformation setup;

  bool enabled;
  bool doRemoveTag = false;
  Node outerContainer;

  HTMLTextTransformation(String tag, String label, {Map<String, String> style, String className, Map<String, String> attributes, String id, bool enabled, bool allowRemove, AsyncTransformation setup}) :
    this.tag = tag,
    this.label = label,
    this.style = style,
    this.attributes = attributes,
    this.className = className,
    this.id = id,
    this.enabled = enabled ?? true,
    this.setup = setup ?? (() => new Future<HTMLTextTransformation>.value(new HTMLTextTransformation(
        tag, label, style: style, className: className, attributes: attributes, id: id, enabled: enabled, allowRemove: allowRemove
    ))),
    this.allowRemove = allowRemove ?? true;

}