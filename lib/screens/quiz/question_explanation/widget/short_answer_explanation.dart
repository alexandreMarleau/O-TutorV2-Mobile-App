import 'package:demo3/model/question.dart';
import 'package:demo3/model/question_attempt.dart';
import 'package:demo3/model/quiz_attempt.dart';
import 'package:flutter/cupertino.dart';

class ShortAnswerExplanation extends StatelessWidget {
  final QuizAttempt _quizAttempt;
  final int index;

  ShortAnswerExplanation({required QuizAttempt quizAttempt, required int quizId})
      : this._quizAttempt = quizAttempt,
        this.index = quizId;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text("You have answered Wrong"),
          Text("your answer: " + _quizAttempt.questionAttempts[index].answer),
          Text("The good answer is " + _quizAttempt.questions[index].shortAnswers!.first.answerText.toString()),
          Text(_quizAttempt.questions[index].explanation),
        ],
      ),
    );
  }
}
