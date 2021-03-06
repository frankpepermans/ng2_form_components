import 'dart:html';

import 'package:angular/angular.dart';

@Injectable()
class HtmlHelpers {
  bool updateElementClasses(Element element, String cssClassName, bool doAdd) {
    final hasClass = element.classes.contains(cssClassName);

    if (!hasClass && doAdd)
      return element.classes.add(cssClassName);
    else if (hasClass && !doAdd) return element.classes.remove(cssClassName);

    return false;
  }
}
