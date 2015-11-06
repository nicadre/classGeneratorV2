# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    String+is_comment.rb                               :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: niccheva <niccheva@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2015/10/08 15:47:42 by niccheva          #+#    #+#              #
#    Updated: 2015/10/08 15:50:42 by niccheva         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

class String

  def is_comment?
    return true if self.start_with? "/*" and self.end_with? "*/"
    false
  end

end
