enum FtpEntityType { file, directory, link }

class FtpEntity {
  FtpEntity(this.type, this.permissions, this.items, this.owner, this.group,
      this.size, this.date, this.name);

  factory FtpEntity.fromString(String e) {
    final m = _regexp.matchAsPrefix(e)!;
    return FtpEntity(
        const {
          '-': FtpEntityType.file,
          'l': FtpEntityType.link,
          'd': FtpEntityType.directory
        }[m[1]]!,
        m[2]!,
        int.parse(m[3]!),
        m[4]!,
        m[5]!,
        int.parse(m[6]!),
        m[7]!,
        m[8]!);
  }

  final FtpEntityType type;
  final String permissions;
  final int items;
  final String owner;
  final String group;
  final int size;
  final String date;
  final String name;

  @override
  String toString() => '${const {
        FtpEntityType.file: '-',
        FtpEntityType.directory: 'd',
        FtpEntityType.link: 'l',
      }[type]!}'
      '$permissions'
      ' ${items.toString().padLeft(8)}'
      ' ${owner.padLeft(8)}'
      ' ${group.padLeft(8)}'
      ' ${size.toString().padLeft(8)}'
      ' ${date.padLeft(8)}'
      ' $name';

  static final _regexp = RegExp(r'^([\-ld])' // Directory flag [1]
      r'([\-rwxs]{9})\s+' // Permissions [2]
      r'(\d+)\s+' // Number of items [3]
      r'(\w+)\s+' // File owner [4]
      r'(\w+)\s+' // File group [5]
      r'(\d+)\s+' // File size in bytes [6]
      r'(\w{3}\s+\d{1,2}\s+(?:\d{1,2}:\d{1,2}|\d{4}))\s+' // date[7]
      r'(.+)$' //file/dir name[8]
      );
}
