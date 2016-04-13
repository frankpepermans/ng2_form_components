library ng2_form_components.helpers.html_text_transformation;

import 'dart:html';

class HTMLTextTransformation {

  final String tag;
  final String label;
  final Map<String, String> style;
  final Map<String, String> attributes;
  final String id;
  final String className;
  final bool isShown;

  bool doRemoveTag = false;
  Element outerContainer;

  HTMLTextTransformation(this.tag, this.label, {Map<String, String> style, String className, Map<String, String> attributes, String id, bool isShown}) :
    this.style = style,
    this.attributes = attributes,
    this.className = className,
    this.id = id,
    this.isShown = isShown ?? true;

}