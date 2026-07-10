// Project imports:
import '../../../core/posts/details_parts/types.dart';
import '../../../core/posts/details_parts/widgets.dart';
import 'types.dart';

final kRule34XyzPostDetailsUIBuilder = PostDetailsUIBuilder(
  preview: {
    DetailsPart.toolbar: (context) =>
        const DefaultInheritedPostActionToolbar<Rule34XyzPost>(),
  },
  full: {
    DetailsPart.toolbar: (context) =>
        const DefaultInheritedPostActionToolbar<Rule34XyzPost>(),
    DetailsPart.tags: (context) =>
        const DefaultInheritedTagsTile<Rule34XyzPost>(),
    DetailsPart.fileDetails: (context) =>
        const DefaultInheritedFileDetailsSection<Rule34XyzPost>(),
  },
);
