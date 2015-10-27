# This holds BZ custom endpoints for updating our
# custom data.

class BzController < ApplicationController

  before_filter :require_user, :only => [:last_user_url]
  skip_before_filter :verify_authenticity_token, :only => [:last_user_url]

  def last_user_url
    @current_user.last_url = params[:last_url]
    @current_user.last_url_title = params[:last_url_title]
    @current_user.save

    render :nothing => true
  end

  def video_link
    obj = {}
    # For PoC I am using a manually generated list of links
    # if this passes the test i will make it automatic via
    # braven.developer@gmail.com
    links = [
      'https://talkgadget.google.com/hangouts/_/h5uscfakbtmoq4upfj3vqudx5ya?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/33mbnww6gddxvidixwbiirf2aaa?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/mcspdwadurnln2lapwourzeanaa?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/bovr3tn7z74jlo5jvkdagzixlaa?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/vvycnh3topzabunpctvyzdrshea?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/kphma7mmdlqpletyg3mepnq3tia?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/bb6frjablw3d246ejqna7umz74a?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/2ndb54z2i5hwniaz44czyg77gea?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/s2utjhxjoxpaksd5vgmytwdljya?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/c3o3zep5bciimgxshywuxbnujea?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/ruqgm7nkczglgqtzgeaweqa574a?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/y5swzttonly63hgjgzi3yob3zaa?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/5hhyqhtv24p3ghd2x2muevuckma?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/gh5qxhjongpvbcv2lwlct7xsima?hl=en&authuser=0',
      'https://talkgadget.google.com/hangouts/_/5d4oidzr7b4z3uyvd5bvtge3taa?hl=en&authuser=0'
    ]
    obj['link'] = links.sample # in the real thing, we will use a database so we never reuse an item either but here it will just be a random one
    render :json => obj
  end
end
