import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../../../../core/constants/app_colors.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  Color get priorityColor {
    switch (task.priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  String get priorityLabel {
    switch (task.priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String get _remainingTimeText {
    if (task.deadline == null) return '';

    final now = DateTime.now();
    final deadline = task.deadline!;

    if (deadline.isBefore(now)) {
      return 'Overdue';
    }

    final remaining = deadline.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours >= 24) {
      final days = hours ~/ 24;
      return '$days day${days > 1 ? 's' : ''} left';
    } else if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''} left';
    } else if (minutes > 0) {
      return '$minutes min left';
    } else {
      return 'Due now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: task.isCompleted ? null : onComplete,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckbox(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildPriorityBadge(),
                          if (task.deadline != null) ...[
                            const SizedBox(width: 8),
                            _buildDeadlineBadge(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildDeleteButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: task.isCompleted ? null : onComplete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: task.isCompleted ? AppColors.success : priorityColor,
            width: 2,
          ),
          color: task.isCompleted ? AppColors.success : Colors.transparent,
        ),
        child: task.isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priorityLabel,
        style: TextStyle(
          color: priorityColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDeadlineBadge() {
    final isOverdue = task.isOverdue;
    final isDueSoon = task.isDueSoon;

    Color color;
    if (task.isCompleted) {
      color = AppColors.textTertiary;
    } else if (isOverdue) {
      color = AppColors.error;
    } else if (isDueSoon) {
      color = AppColors.warning;
    } else {
      color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _remainingTimeText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      icon: Icon(
        Icons.delete_outline_rounded,
        color: AppColors.textTertiary,
        size: 22,
      ),
      onPressed: onDelete,
    );
  }
}
