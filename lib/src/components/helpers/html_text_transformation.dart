library ng2_form_components.helpers.html_text_transformation;

class HTMLTextTransformation {

  final String tag;
  final String label;
  final Map<String, String> style;
  final String id;

  HTMLTextTransformation(this.tag, this.label, {Map<String, String> style, String id}) :
    this.style = style,
    this.id = id;

}