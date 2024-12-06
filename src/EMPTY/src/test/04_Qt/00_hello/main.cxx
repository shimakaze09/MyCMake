//
// Created by Admin on 6/12/2024.
//

#include <QApplication>
#include "mainwindow.hxx"


int main(int argc, char* argv[]) {
  QApplication a(argc, argv);
  MainWindow w;
  w.show();

  return a.exec();
}
