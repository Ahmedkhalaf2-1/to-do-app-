import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 32)
enum TaskStatus {
  @HiveField(0) pending,
  @HiveField(1) inProgress,
  @HiveField(2) done,
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0) String title;
  @HiveField(1) String category;
  @HiveField(2) DateTime date;
  @HiveField(3) String description;
  @HiveField(4) TaskStatus status;
  @HiveField(5) List<String> imagePaths;
  @HiveField(6) String assignee;
  @HiveField(7) Map<String, bool> checklist;
  @HiveField(8) int? categoryId;
  @HiveField(9) bool archived; // <-- NEW

  Task({
    required this.title,
    required this.category,
    required this.date,
    this.description = '',
    this.status = TaskStatus.pending,
    List<String>? imagePaths,
    this.assignee = 'You',
    Map<String, bool>? checklist,
    this.categoryId,
    this.archived = false, // <-- default
  })  : imagePaths = imagePaths ?? [],
        checklist = checklist ?? {};

  DateTime get dayKey => DateTime(date.year, date.month, date.day);
  bool get isToday {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  bool get isOverdue {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    return dayKey.isBefore(todayKey) && status != TaskStatus.done;
  }

  double get checklistProgress {
    if (checklist.isEmpty) return 0;
    final done = checklist.values.where((v) => v).length;
    return done / checklist.length;
  }

  int get effectiveCategoryId => categoryId ?? 0;

  Task copyWith({
    String? title,
    String? category,
    DateTime? date,
    String? description,
    TaskStatus? status,
    List<String>? imagePaths,
    String? assignee,
    Map<String, bool>? checklist,
    int? categoryId,
    bool? archived, // <-- NEW
  }) {
    return Task(
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      status: status ?? this.status,
      imagePaths: imagePaths ?? List<String>.from(this.imagePaths),
      assignee: assignee ?? this.assignee,
      checklist: checklist ?? Map<String, bool>.from(this.checklist),
      categoryId: categoryId ?? this.categoryId,
      archived: archived ?? this.archived, // <-- NEW
    );
  }

  void addAttachment(String path) => imagePaths.add(path);
  bool removeAttachment(String path) => imagePaths.remove(path);
  void toggleChecklistItem(String key) {
    final current = checklist[key] ?? false;
    checklist[key] = !current;
  }
  void setChecklistItem(String key, bool value) {
    checklist[key] = value;
  }

  static int compareByDate(Task a, Task b) => a.date.compareTo(b.date);

  @override
  String toString() =>
      'Task(title: $title, category: $category, categoryId: ${categoryId ?? 0}, date: $date, status: $status, archived: $archived, attachments: ${imagePaths.length})';
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending: return 'Pending';
      case TaskStatus.inProgress: return 'In progress';
      case TaskStatus.done: return 'Done';
    }
  }

  static TaskStatus fromLabel(String label) {
    final n = label.toLowerCase().replaceAll('_', ' ').trim();
    switch (n) {
      case 'pending': return TaskStatus.pending;
      case 'in progress':
      case 'inprogress': return TaskStatus.inProgress;
      case 'done':
      case 'completed': return TaskStatus.done;
      default: return TaskStatus.pending;
    }
  }
}
