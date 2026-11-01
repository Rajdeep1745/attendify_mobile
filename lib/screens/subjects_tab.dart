import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/subject_tree_model.dart';
import '../services/subject_tree_service.dart';

class SubjectsTab extends StatefulWidget {
  final List<SubjectModel> subjects;
  final SubjectModel? selectedSubject;
  final ValueChanged<SubjectModel?> onSelect;
  final Future<void> Function() onReload;

  const SubjectsTab({
    super.key,
    required this.subjects,
    required this.selectedSubject,
    required this.onSelect,
    required this.onReload,
  });

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  late Future<List<ProgrammeTreeNode>> _treeFuture;

  @override
  void initState() {
    super.initState();

    _treeFuture = SubjectTreeService.loadTree();
  }

  @override
  void didUpdateWidget(covariant SubjectsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.subjects != widget.subjects) {
      _treeFuture = SubjectTreeService.loadTree();
    }
  }

  Future<void> _refresh() async {
    await widget.onReload();

    if (!mounted) return;

    setState(() {
      _treeFuture = SubjectTreeService.loadTree();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.deepPurple,
      onRefresh: _refresh,
      child: FutureBuilder<List<ProgrammeTreeNode>>(
        future: _treeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (snapshot.hasError) {
            return _errorView(snapshot.error.toString());
          }

          final programmes = snapshot.data ?? [];

          if (programmes.isEmpty) {
            return _emptyView();
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _header(programmes.length),

              const SizedBox(height: 20),

              ...programmes.map(
                (programme) => _ProgrammeCard(
                  programme: programme,
                  availableSubjects: widget.subjects,
                  selectedSubject: widget.selectedSubject,
                  onSelect: widget.onSelect,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _header(int programmeCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Subjects",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.6,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          "Select a subject to manage its attendance.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xffEEEAFE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.deepPurple,
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.subjects.length} assigned subject${widget.subjects.length == 1 ? '' : 's'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      "Tap a subject to make it active",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _errorView(String error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),

        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xffffeeee),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Unable to load subjects",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 7),

                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _refresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Try Again"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _emptyView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),

        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xffEEEAFE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "No subjects available",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  "No subjects assigned to this teacher were found.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// PROGRAMME CARD
// =============================================================

class _ProgrammeCard extends StatefulWidget {
  final ProgrammeTreeNode programme;
  final List<SubjectModel> availableSubjects;
  final SubjectModel? selectedSubject;
  final ValueChanged<SubjectModel?> onSelect;

  const _ProgrammeCard({
    required this.programme,
    required this.availableSubjects,
    required this.selectedSubject,
    required this.onSelect,
  });

  @override
  State<_ProgrammeCard> createState() => _ProgrammeCardState();
}

class _ProgrammeCardState extends State<_ProgrammeCard> {
  bool expanded = true;

  bool _isAvailable(String subjectId) {
    return widget.availableSubjects.any(
      (subject) => subject.subjectId == subjectId,
    );
  }

  int _availableCount() {
    var count = 0;

    for (final semester in widget.programme.semesters) {
      for (final subject in semester.subjects) {
        if (_isAvailable(subject.subjectId)) {
          count++;
        }
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = _availableCount();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xffEEEAFE), Color(0xffE5DFFF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.programme.programme,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "$availableCount assigned subject${availableCount == 1 ? '' : 's'}",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 21,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  ...widget.programme.semesters.map(
                    (semester) => _SemesterCard(
                      semester: semester,
                      isAvailable: _isAvailable,
                      availableSubjects: widget.availableSubjects,
                      selectedSubject: widget.selectedSubject,
                      onSelect: widget.onSelect,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================
// SEMESTER CARD
// =============================================================

class _SemesterCard extends StatefulWidget {
  final SemesterTreeNode semester;
  final bool Function(String subjectId) isAvailable;
  final List<SubjectModel> availableSubjects;
  final SubjectModel? selectedSubject;
  final ValueChanged<SubjectModel?> onSelect;

  const _SemesterCard({
    required this.semester,
    required this.isAvailable,
    required this.availableSubjects,
    required this.selectedSubject,
    required this.onSelect,
  });

  @override
  State<_SemesterCard> createState() => _SemesterCardState();
}

class _SemesterCardState extends State<_SemesterCard> {
  bool expanded = false;

  SubjectModel? _findSubject(String subjectId) {
    for (final subject in widget.availableSubjects) {
      if (subject.subjectId == subjectId) {
        return subject;
      }
    }

    return null;
  }

  int _availableCount() {
    return widget.semester.subjects
        .where((subject) => widget.isAvailable(subject.subjectId))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = _availableCount();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xffFAFAFD),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F3FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.blue,
                      size: 19,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Semester ${widget.semester.semester}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          "$availableCount subject${availableCount == 1 ? '' : 's'} assigned",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 21,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  ...widget.semester.subjects.map((subject) {
                    final available = widget.isAvailable(subject.subjectId);

                    final selected =
                        widget.selectedSubject?.subjectId == subject.subjectId;

                    final model = _findSubject(subject.subjectId);

                    return _SubjectRow(
                      subject: subject,
                      available: available,
                      selected: selected,
                      model: model,
                      onSelect: widget.onSelect,
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================
// SUBJECT ROW
// =============================================================

class _SubjectRow extends StatelessWidget {
  final SubjectTreeNode subject;
  final bool available;
  final bool selected;
  final SubjectModel? model;
  final ValueChanged<SubjectModel?> onSelect;

  const _SubjectRow({
    required this.subject,
    required this.available,
    required this.selected,
    required this.model,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffF1EEFF) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? const Color(0xffD8D0FF) : Colors.grey.shade100,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: available
            ? () {
                onSelect(model);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: available
                      ? selected
                            ? const Color(0xffE4DEFF)
                            : const Color(0xffEEEAFE)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 19,
                  color: available ? Colors.deepPurple : Colors.grey.shade400,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: available ? Colors.black87 : Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      available
                          ? selected
                                ? "Currently selected"
                                : "Available"
                          : "Not assigned",
                      style: TextStyle(
                        color: selected
                            ? Colors.deepPurple
                            : Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              if (selected)
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                )
              else if (available)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
