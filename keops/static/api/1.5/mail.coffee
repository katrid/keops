

class Comments
  constructor: (@scope) ->
    @model = @scope.$parent.model

    @scope.$parent.$watch 'recordId', (key) =>
      @scope.loading = Katrid.i18n.gettext 'Loading...'
      setTimeout =>
        @masterChanged(key)
        @scope.$apply =>
          @scope.loading = null
      , 1000

    @items = []

  masterChanged: (key) ->
    if key
      svc = new Katrid.Services.Model('mail.message')
      svc.post 'get_messages', null, { args: [@scope.$parent.record.messages] }
      .done (res) =>
        @scope.$apply =>
          @items = res.result.data

  postMessage: (msg) ->
    @model.post 'post_message', null, { args: [[@scope.$parent.recordId]], kwargs: { content: msg, content_subtype: 'html', format: true } }
    .done (res) =>
      msgs = res.result
      @scope.message = ''
      @scope.$apply =>
        @items = msgs.concat(@items)


Katrid.uiKatrid.directive 'comments', ->
  restrict: 'E'
  scope: {}
  replace: true
  link: (scope, element, attrs) ->
    form = $(element).closest('div[ng-form=form]')
    form.append(element)

  template: ->
    """
  <div class="content panel panel-default">
    <div class="container comments">
      <mail-comments/>
    </div>
  </div>
"""

Katrid.uiKatrid.directive 'mailComments', ->
  restrict: 'E'
  replace: true,
  link: (scope, element, attrs) ->
    scope.comments = new Comments(scope)
    scope.showEditor = ->
      $('#mail-editor').show()
      $('#mail-msgEditor').focus()
      return true

  template: ->
    """
<div>
      <h3>#{Katrid.i18n.gettext 'Comments'}</h3>
      <div class="form-group">
      <button class="btn btn-default" ng-click="showEditor();">#{Katrid.i18n.gettext 'New message'}</button>
      <button class="btn">#{Katrid.i18n.gettext 'Log an internal note'}</button>
      </div>
      <div id="mail-editor" style="display: none;">
        <div class="form-group">
          <textarea id="mail-msgEditor" class="form-control" ng-model="message"></textarea>
        </div>
        <div class="from-group">
          <button class="btn btn-primary" ng-click="comments.postMessage(message)">#{Katrid.i18n.gettext 'Send'}</button>
        </div>
      </div>

      <hr>

      <div ng-show="loading">${loading}</div>
      <div class="comment media col-sm-12" ng-repeat="comment in comments.items">
        <div class="media-left">
          <img src="/static/web/static/assets/img/avatar.png" class="avatar img-circle">
        </div>
        <div class="media-body">
          <strong>${ comment.author[1] }</strong> - <span title="${comment.date_time|moment:'LLLL'}"> ${comment.date_time|moment}</span>
          <div class="clearfix"></div>
          <div>
            ${comment.content}
          </div>
        </div>
      </div>
</div>
"""


class MailFollowers


class MailComments extends Katrid.UI.Widgets.Widget
  tag: 'mail-comments'

  spanTemplate: (scope, el, attrs, field) ->
    return ''


Katrid.UI.Widgets.MailComments = MailComments
