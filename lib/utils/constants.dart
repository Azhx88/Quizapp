import 'package:quizzapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

const kAppName = 'Quizapp';
const kHostPort = 4567;
const kServiceType = '_quizzap._tcp';
const kPinLength = 6;

// Answer button colors (matches stitch reference)
const kColorRed    = AppColors.answerRed;
const kColorBlue   = AppColors.answerBlue;
const kColorYellow = AppColors.answerYellow;
const kColorGreen  = AppColors.answerGreen;

const List<Color> kAnswerColors = AppColors.answerColors;



const kDefaultTimePerQuestion = 30;
const kMaxScore = 1000;
const kWrongPenalty = 25;
const kStreakThreshold = 3;
