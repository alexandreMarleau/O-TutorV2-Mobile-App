import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:demo3/localization/app_localizations.dart';
import 'package:demo3/model/answer.dart';
import 'package:demo3/model/question.dart';
import 'package:demo3/model/question_attempt.dart';
import 'package:demo3/model/quiz.dart';
import 'package:demo3/model/quiz_attempt.dart';
import 'package:demo3/model/shortAnswer.dart';
import 'package:demo3/network/api_response.dart';
import 'package:demo3/screens/quiz/quiz_process/blocs/question_bloc.dart';
import 'package:demo3/screens/quiz/quiz_process/widgets/answer_details.dart';
import 'package:demo3/screens/quiz/quiz_process/widgets/exit_quiz_dialog.dart';
import 'package:demo3/screens/quiz/quiz_process/widgets/multiple_choice.dart';

import 'package:demo3/screens/quiz/quiz_process/widgets/quiz_card.dart';
import 'package:demo3/custom_painter/bg_circles.dart';
import 'package:demo3/screens/quiz/quiz_process/widgets/score_details.dart';
import 'package:demo3/screens/quiz/quiz_process/widgets/short_answer.dart';
import 'package:demo3/screens/quiz/quiz_process/widgets/timer_ended_dialog.dart';
import 'package:demo3/screens/util/error_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';

import 'blocs/quiz_attempt_bloc.dart';

class QuizPage extends StatefulWidget {
  //Quiz en cours
  final Quiz quiz;

  late QuizAttempt _quizAttempt;
  //Liste des questions du quiz en cours
  List<Question> _questions = [];

  QuizPage({Key? key, required this.quiz}) : super(key: key);

  @override
  _QuizState createState() {
    return _QuizState();
  }
}

class _QuizState extends State<QuizPage> {
  QuizAttemptBloc? _bloc;
  CountDownController _timerController = CountDownController();

  @override
  QuizPage get widget => super.widget;

  @override
  void initState() {
    super.initState();
    _bloc = QuizAttemptBloc();
    _bloc!.createQuizAttempt(widget.quiz.id);
  }

  void refresh() {
    setState(() {
      _bloc!.createQuizAttempt(widget.quiz.id);
    });
  }

  //Réponse de la question en cours
  late String _answer = "";
  late bool _isTrue = false;
  var _questionIndex = 0; //Index de la question en cours

  //Retourne le temps écoulés depuis la derniere question répondu
  int _getElapsedTime() {
    int lastTimeAnswered = Duration(
            minutes: int.parse(widget._quizAttempt.duration.substring(0, 2)),
            seconds: int.parse(widget._quizAttempt.duration.substring(3, 5)))
        .inSeconds;

    int currentTime = Duration(
            minutes: int.parse(_timerController.getTime().substring(0, 2)),
            seconds: int.parse(_timerController.getTime().substring(3, 5)))
        .inSeconds;

    return lastTimeAnswered - currentTime;
  }

  //Méthode pour enregistrer définitivement la réponse de la question en cours
  //et ensuite passer a la prochaine question
  void _answerQuestion() {
    setState(() {
      _questionIndex = _questionIndex + 1;
    });
    String type;
    int obtainedMark = 0;
    Question currentQuestion = widget._questions[_questionIndex - 1];

    if (currentQuestion.shortAnswers!.isEmpty) {
      type = "multiplechoice";
    } else {
      type = "shortanswer";
    }
    if (_isTrue) {
      obtainedMark = currentQuestion.weight;
    }
    //Ajout de la réponse a la liste de réponse choisie
    widget._quizAttempt.questionAttempts
        .add(QuestionAttempt(currentQuestion.questionId, 1, obtainedMark, _isTrue, _getElapsedTime(), type, _answer));

    widget._quizAttempt.currentQuestionId = currentQuestion.questionId;
    widget._quizAttempt.duration = _timerController.getTime(); //Mise a jour de la durée restante

    print(widget._quizAttempt);

    _answer = "";
    _isTrue = false;
  }

  //Méthode callback pour set la réponse (ShortAnswer) choisie de la question en cours
  void _setShortAnswer(dynamic newAnswer) {
    setState(() {
      _answer = newAnswer;
      _isTrue = isShortAnswerTrue(_answer);
    });
    print('New Answer for question ' + _questionIndex.toString() + ' was set');
    print('Choosed Answer is: ' + _answer);
  }

  //Méthode callback pour set la réponse (MultipleChoice) choisie de la question en cours
  void _setQuestionAnswer(Answer newAnswer) {
    setState(() {
      _answer = newAnswer.answer;
      _isTrue = newAnswer.isTrue;
    });
    print('New Answer for question ' + _questionIndex.toString() + ' was set');
    print('Choosed Answer is: ' + _answer);
  }

  //permet de verifier si la réponse en input est vrai
  bool isShortAnswerTrue(String answer) {
    List<ShortAnswer> shortAnswers = widget._questions[_questionIndex].shortAnswers!;
    bool isTrue = false;
    shortAnswers.forEach((element) {
      if (element.answer == answer) {
        isTrue = true;
      }
    });
    return isTrue;
  }

  //Méthod appeler lorsque le temps limite du quiz est écoulé
  void saveQuizAttempt() {
    _bloc!.saveQuizAttempt(widget._quizAttempt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            Positioned(
              bottom: -600,
              right: -350,
              height: 620,
              child: CustomPaint(
                size: Size(370, (360 * 1.6666666666666667).toDouble()),
                painter: RPSCustomPainter180(),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: StreamBuilder<ApiResponse<QuizAttempt>>(
                  stream: _bloc!.quizAttemptStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      switch (snapshot.data!.status) {
                        case Status.LOADING:
                          return Container(
                            child: SpinKitDoubleBounce(color: Colors.lightBlue.shade100),
                          );
                        case Status.COMPLETED:
                          widget._quizAttempt = snapshot.data!.data;
                          widget._questions = snapshot.data!.data.questions;
                          /*if (widget._quizAttempt.currentQuestionId != 0) {
                            //Cherche le bon index de la question si le quiz avait deja commencer.

                            _questionIndex = widget._questions
                                .indexWhere((q) => q.questionId == widget._quizAttempt.currentQuestionId);
                            print("Starting Index set to: " + _questionIndex.toString());
                            _indexIsSet = true;
                          }*/
                          return Column(
                            children: [
                              if (_questionIndex < widget._questions.length)
                                Container(
                                  padding: EdgeInsets.only(top: 10),
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height,
                                  child: Column(
                                    children: <Widget>[
                                      Stack(
                                        children: [
                                          Align(
                                            //Countdown timer

                                            child: CircularCountDownTimer(
                                              duration: Duration(
                                                      minutes: int.parse(widget._quizAttempt.duration.substring(0, 2)),
                                                      seconds: int.parse(widget._quizAttempt.duration.substring(3, 5)))
                                                  .inSeconds,
                                              initialDuration: 0,
                                              controller: _timerController,
                                              width: MediaQuery.of(context).size.width / 7,
                                              height: MediaQuery.of(context).size.height / 7,
                                              ringColor: Colors.transparent,
                                              ringGradient: null,
                                              fillColor: Colors.orange,
                                              fillGradient: null,
                                              backgroundColor: null,
                                              backgroundGradient: null,
                                              strokeWidth: 3.0,
                                              strokeCap: StrokeCap.round,
                                              textStyle: TextStyle(
                                                  fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.bold),
                                              textFormat: CountdownTextFormat.MM_SS,
                                              isReverse: true,
                                              isReverseAnimation: true,
                                              isTimerTextShown: true,
                                              autoStart: true,
                                              onStart: () {
                                                print('Quiz Started');
                                              },
                                              onComplete: () {
                                                _answerQuestion();
                                                _questionIndex = widget._questions.length + 1;
                                                TimerEndedDialog.showMyDialog(context);
                                              },
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: IconButton(
                                              padding: EdgeInsets.only(top: 40, right: 20),
                                              onPressed: () {
                                                var popupDialog = ExitQuizDialog(context, saveQuizAttempt);
                                                popupDialog.showMyDialog();
                                              },
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        child: Column(
                                          children: <Widget>[
                                            QuizCard(questions: widget._questions, questionIndex: _questionIndex),
                                            //Affichage varie selon type de question
                                            //Choix de Réponse ------------------------------
                                            if (widget._questions[_questionIndex].multipleAnswers!.isNotEmpty)
                                              MultipleChoice(
                                                  question: widget._questions[_questionIndex],
                                                  setAnswerCallback: _setQuestionAnswer),
                                            //Réponse Courte ------------------------------
                                            if (widget._questions[_questionIndex].shortAnswers!.isNotEmpty)
                                              ShortAnswerWidget(
                                                setAnswerCallback: _setShortAnswer,
                                              ),
                                          ],
                                        ),
                                      ),

                                      Spacer(),
                                      // Bouton suivant
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.lightBlue,
                                          borderRadius: BorderRadius.all(Radius.circular(90)),
                                        ),
                                        margin: EdgeInsets.all(40),
                                        padding: EdgeInsets.only(left: 40, right: 40),
                                        child: AnswerDetailsButton(
                                          onPressed: () {
                                            _answerQuestion();
                                            Navigator.pop(context);
                                          },
                                          answerText: _answer,
                                          isTrue: _isTrue,
                                        ),
                                      ),
                                      Spacer(flex: 3),
                                    ],
                                  ),
                                ),
                              if (_questionIndex >= widget._questions.length)
                                ScoreDetails(
                                  quizAttempt: widget._quizAttempt,
                                ),
                            ],
                          );
                          break;
                        case Status.ERROR:
                          return ErrorPopUp(snapshot, refresh);
                          break;
                      }
                    }
                    return Text("No data");
                  }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _bloc!.dispose();
  }
}
