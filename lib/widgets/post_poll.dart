import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import '../theme.dart';

/// Encuesta real de un post (`GET /posts/{id}/poll` + `POST /polls/{id}/vote`).
///
/// El feed (`PostOut`) no embebe la encuesta, por eso este widget la pide solo
/// cuando el post es de tipo `POLL`.
class PostPollView extends StatefulWidget {
  final String postId;
  final PollAttachment? initialPoll;

  const PostPollView({
    super.key,
    required this.postId,
    this.initialPoll,
  });

  @override
  State<PostPollView> createState() => _PostPollViewState();
}

class _PostPollViewState extends State<PostPollView> {
  PollAttachment? _poll;
  final Set<String> _selected = {};
  bool _loading = true;
  bool _voting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _poll = widget.initialPoll;
    if (_poll != null) {
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final poll = await PostService.getPoll(widget.postId);
      if (!mounted) return;
      setState(() {
        _poll = poll;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit(List<String> ids) async {
    final poll = _poll;
    if (poll == null || _voting || !poll.canVote || ids.isEmpty) return;

    setState(() => _voting = true);
    try {
      final updated = await PostService.votePoll(poll.id, ids);
      if (!mounted) return;
      setState(() {
        _poll = updated;
        _selected.clear();
        _voting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _voting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo votar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DevColors.primary,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            const Icon(Icons.poll_outlined, size: 16, color: DevColors.mutedFg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Encuesta no disponible',
                style: DevTheme.bodySecondary(size: 11.5),
              ),
            ),
            TextButton(
              onPressed: _load,
              child: Text('Reintentar',
                  style: DevTheme.body(size: 11.5, color: DevColors.primary)),
            ),
          ],
        ),
      );
    }

    final poll = _poll;
    if (poll == null) return const SizedBox.shrink();

    final total = poll.totalVotes > 0
        ? poll.totalVotes
        : poll.options.fold<int>(0, (sum, o) => sum + o.votesCount);
    final showResults = !poll.canVote || poll.showResults;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DevColors.cardRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DevColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_rounded, size: 16, color: DevColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  poll.question,
                  style: DevTheme.body(size: 13, w: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...poll.options.map((option) {
            final selected = _selected.contains(option.id);
            final voted = poll.votedOptionIds.contains(option.id);
            final pct = total == 0 ? 0.0 : option.votesCount / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: poll.canVote
                    ? () {
                        if (poll.allowMultiple) {
                          setState(() {
                            if (selected) {
                              _selected.remove(option.id);
                            } else {
                              _selected.add(option.id);
                            }
                          });
                        } else {
                          _submit([option.id]);
                        }
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: DevColors.muted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected || voted
                          ? DevColors.primary.withValues(alpha: 0.7)
                          : DevColors.border,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (showResults && pct > 0)
                        Positioned.fill(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              color: DevColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9),
                        child: Row(
                          children: [
                            Icon(
                              voted
                                  ? Icons.check_circle_rounded
                                  : selected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: voted || selected
                                  ? DevColors.primary
                                  : DevColors.mutedFg,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.text,
                                style: DevTheme.body(size: 12.5),
                              ),
                            ),
                            if (showResults)
                              Text(
                                '${(pct * 100).round()}%',
                                style: DevTheme.bodySecondary(size: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (poll.allowMultiple && poll.canVote) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected.isEmpty || _voting
                    ? null
                    : () => _submit(_selected.toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevColors.primary,
                  foregroundColor: DevColors.primaryFg,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _voting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Votar',
                        style: DevTheme.body(size: 12, w: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                total == 1 ? '1 voto' : '$total votos',
                style: DevTheme.bodySecondary(size: 10.5),
              ),
              if (poll.hasVoted) ...[
                const SizedBox(width: 6),
                Text('· Ya votaste',
                    style: DevTheme.bodySecondary(size: 10.5)),
              ],
              if (poll.isClosed) ...[
                const SizedBox(width: 6),
                Text('· Cerrada',
                    style: DevTheme.bodySecondary(size: 10.5)),
              ],
              const Spacer(),
              if (_voting)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DevColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
