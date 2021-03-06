'''**********************************************************************
    Copyright (C) 2009-2015  The Freeciv-web project

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

***********************************************************************'''
import smtplib
import json
import configparser
import re
import time

from email.mime.text import MIMEText

class MailSender():

  settings = configparser.ConfigParser()
  settings.read("settings.ini")

  smtp_login=settings.get("Config", "smtp_login")
  smtp_password=settings.get("Config", "smtp_password")
  smtp_host=settings.get("Config", "smtp_host")
  smtp_port=settings.get("Config", "smtp_port")
  smtp_sender=settings.get("Config", "smtp_sender")

  def send_message_via_smtp(self, from_, to, mime_string):
    time.sleep(2);
    smtp = smtplib.SMTP(self.smtp_host, int(self.smtp_port))
    smtp.login(self.smtp_login, self.smtp_password);
    smtp.sendmail(from_, to, mime_string)
    smtp.quit()


  def send_mailgun_message(self, to, subject, text):
    msg = MIMEText(text, _charset='utf-8')
    msg['Subject'] = subject
    msg['From'] = self.smtp_sender; 
    msg['To'] = to
    self.send_message_via_smtp(self.smtp_sender, to, msg.as_string())


  #Send the actual PBEM e-mail turn invitation message.
  def send_email(self, player_name, players, email_address, filename, turn):
    print("Sending e-mail to: " + email_address);

    msg = "To " + player_name +"\n\n" + \
      "It is now your turn to play Freeciv-Web. You are receiving this e-mail because you " + \
      "are participating in a Play-By-Email game of Freeciv-web.\n\n" + \
      "Please follow this link to play your turn: " + \
      "https://play.freeciv.org/webclient/?action=pbem&savegame="+ filename + "\n\n";
    msg += "Players in game: ";
    for p in players:
      msg += p + ", ";
    msg += "\n\n";
    msg += "Please complete your turn within 7 days, the other player will be waiting for you. ";
    msg += "Play-By-Email is currently a Beta-feature, please report any problems playing " +\
            "here: http://forum.freeciv.org/f/viewforum.php?f=24\n\n";
    msg += "Freeciv-Web is a free and open source empire-building strategy game " + \
             "inspired by the history of human civilization.\n\n";
    msg += "The Freeciv-web project - https://play.freeciv.org\n\n";
    self.send_mailgun_message(email_address, "Freeciv-Web: It's your turn to play! Turn: " \
        + str(turn), msg);

  def send_invitation(self, invitation_from, invitation_to):
    sender = re.sub(r'\W+', '', invitation_from);
    msg = "Hello! You have been invited by " + sender + " to a " \
    "multiplayer game on Freeciv-web. This is a play-by-email game that you can play " \
    "in your browser for free.\n\nFollow this link to play against " + sender + ": " \
     "https://play.freeciv.org/pbem?u=" + sender + "\n\n\n"; 
    msg += "Play-By-Email is currently a Beta-feature, please report any problems playing " +\
            "here: http://forum.freeciv.org/f/viewforum.php?f=24\n\n";
    msg += "Freeciv-Web is a free and open source empire-building strategy game " + \
             "inspired by the history of human civilization.\n\n";
    msg += "The Freeciv-web project - https://play.freeciv.org\n\n";

    self.send_mailgun_message(invitation_to, "Freeciv-Web: Join my game!" , msg);


  # send email with ranking after game is over.
  def send_game_result_mail(self, winner, winner_score, winner_email, losers, losers_score, losers_email):
    print("Sending ranklog result to " + winner_email + " and " + losers_email);
    msg_winner = "To " + winner + "\nYou have won the game of Freeciv-web against " + losers + ".\n";
    msg_winner += "Winner score: " + winner_score + "\n\n"
    msg_winner += "The Freeciv-web project - https://play.freeciv.org";
    self.send_mailgun_message("postmaster@freeciv.mailgun.org", winner_email, 
      "Freeciv-Web: You won!", msg_winner);

    msg_loser = "To " + losers + "\nYou have lost the game of Freeciv-web against " + winner + ".\n";
    msg_loser += "Winner score: " + winner_score + "\n\n"
    msg_loser += "The Freeciv-web project - https://play.freeciv.org";
    self.send_mailgun_message(losers_email, "Freeciv-Web: You lost!", msg_loser);
