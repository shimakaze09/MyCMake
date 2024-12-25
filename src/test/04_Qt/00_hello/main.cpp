//
// Created by Admin on 26/12/2024.
//

#include <QApplication>
#include "mainwindow.h"

int main(int argc, char* argv[]) {
  QApplication a(argc, argv);
  MainWindow w;
  w.show();

  return a.exec();
}